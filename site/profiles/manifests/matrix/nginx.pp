# @summary Nginx and Let's Encrypt configuration for the Matrix profile
#
# This class manages the host-level Nginx server and Let's Encrypt certificates.
# It handles the ACME challenges, provisions SSL certificates for both the delegation
# server (`voxpupuli.party`) and the Matrix API Reverse Proxy (`matrix01.voxpupu.li`).
#
# It creates upstreams mapping to the local Synapse workers and routes the incoming federation,
# client, media, and sync traffic to the appropriate Dockerized endpoints.
#
class profiles::matrix::nginx {
  $domain = 'voxpupuli.party'
  $matrix_domain = 'matrix01.voxpupu.li'

  # ---------------------------------------------------------
  # voxpupuli.party (DELEGATION SERVER)
  # ---------------------------------------------------------
  $root = "/srv/${domain}"

  file {
    default:
      ensure => 'directory',
    ;
    $root:
    ;
    "${root}/.well-known":
    ;
    "${root}/.well-known/matrix/":
    ;
    [
      "${root}/.well-known/matrix/client",
      "${root}/.well-known/matrix/server",
    ]:
      ensure => 'file',
    ;
  }

  if fact("letsencrypt_directory.\"${domain}\"") {
    $path = fact("letsencrypt_directory.\"${domain}\"")
    $ssl = {
      ssl_key                   => "${path}/privkey.pem",
      ssl_cert                  => "${path}/fullchain.pem",
      ssl                       => true,
      ssl_port                  => 443,
      ssl_session_timeout       => '1d',
      ssl_session_tickets       => 'off',
      ssl_protocols             => 'TLSv1.2 TLSv1.3',
      ssl_prefer_server_ciphers => 'off',
      add_header                => {
        'Strict-Transport-Security' => {
          'max-age=63072000' => 'always',
        },
      },
    }
  } else {
    $ssl = {}
  }

  nginx::resource::server { $domain:
    listen_port          => 80,
    server_name          => [$domain],
    ipv6_enable          => true,
    ipv6_listen_options  => '',
    http2                => 'on',
    access_log           => "/var/log/nginx/${domain}.access.log",
    error_log            => "/var/log/nginx/${domain}.error.log",
    format_log           => 'combined',
    use_default_location => false,
    index_files          => [],
    www_root             => $root,
    *                    => $ssl,
  }

  letsencrypt::certonly { $domain:
    domains         => [$domain],
    plugin          => 'nginx',
    manage_cron     => true,
    additional_args => ['--no-redirect'],
    require         => [
      Nginx::Resource::Server[$domain],
      Nginx::Resource::Location[
        "${domain} Let's Encrypt challenges",
        "${domain} acme-challenge directory",
      ],
    ],
  }

  # ---------------------------------------------------------
  # matrix01.voxpupu.li (SYNAPSE REVERSE PROXY)
  # ---------------------------------------------------------

  # Upstreams matching compose mapping
  nginx::resource::upstream {
    'synapse_client':
      members => ['127.0.0.1:8081', '127.0.0.1:8082'];
    'synapse_federation':
      members => ['127.0.0.1:8081', '127.0.0.1:8082', '127.0.0.1:8083'];
    'synapse_media':
      members => ['127.0.0.1:8084'];
    'synapse_main':
      members => ['127.0.0.1:8008'];
  }

  if fact("letsencrypt_directory.\"${matrix_domain}\"") {
    $matrix_path = fact("letsencrypt_directory.\"${matrix_domain}\"")
    $matrix_ssl = {
      ssl_key                   => "${matrix_path}/privkey.pem",
      ssl_cert                  => "${matrix_path}/fullchain.pem",
      ssl                       => true,
      ssl_port                  => 443,
      ssl_session_timeout       => '1d',
      ssl_session_cache         => 'shared:SSL:10m',
      ssl_session_tickets       => 'off',
      ssl_protocols             => 'TLSv1.2 TLSv1.3',
      ssl_ciphers               => 'ECDHE+AESGCM:DHE+AESGCM:ECDHE+ECDSA+AES+SHA256',
      ssl_prefer_server_ciphers => 'off',
      add_header                => {
        'Strict-Transport-Security' => {
          'max-age=63072000' => 'always',
        },
      },
    }
  } else {
    $matrix_ssl = {}
  }

  nginx::resource::server { $matrix_domain:
    listen_port          => 80,
    server_name          => [$matrix_domain],
    client_max_body_size => '50m',
    ipv6_enable          => true,
    ipv6_listen_options  => '',
    http2                => 'on',
    access_log           => "/var/log/nginx/${matrix_domain}.access.log",
    error_log            => "/var/log/nginx/${matrix_domain}.error.log",
    format_log           => 'combined',
    use_default_location => false,
    *                    => $matrix_ssl,
  }

  letsencrypt::certonly { $matrix_domain:
    domains         => [$matrix_domain],
    plugin          => 'nginx',
    manage_cron     => true,
    additional_args => ['--no-redirect'],
    require         => [
      Nginx::Resource::Server[$matrix_domain],
      Nginx::Resource::Location[
        "${matrix_domain} Let's Encrypt challenges",
        "${matrix_domain} acme-challenge directory",
      ],
    ],
  }

  # ---------------------------------------------------------
  # Nginx Locations Multi-Declaration
  # ---------------------------------------------------------

  # Acme and static locations
  nginx::resource::location {
    default:
      index_files => [],
    ;
    "${domain} Let's Encrypt challenges":
      server   => $domain,
      www_root => '/var/lib/letsencrypt/',
      location => '^~ /.well-known/acme-challenge/',
    ;
    "${domain} acme-challenge directory":
      server              => $domain,
      location_cfg_append => { 'return' => '404', },
      location            => '= /.well-known/acme-challenge/',
    ;
    "${matrix_domain} Let's Encrypt challenges":
      server   => $matrix_domain,
      www_root => '/var/lib/letsencrypt/',
      location => '^~ /.well-known/acme-challenge/',
    ;
    "${matrix_domain} acme-challenge directory":
      server              => $matrix_domain,
      location_cfg_append => { 'return' => '404', },
      location            => '= /.well-known/acme-challenge/',
    ;
    "${matrix_domain} root fallback":
      server              => $matrix_domain,
      location            => '/',
      location_cfg_append => { 'return' => '404' },
    ;
  }

  # Reverse proxy endpoints
  $proxy_params = {
    'X-Forwarded-For'   => '$remote_addr',
    'X-Forwarded-Proto' => '$scheme',
    'Host'              => '$host',
  }

  nginx::resource::location {
    default:
      server           => $matrix_domain,
      proxy_set_header => $proxy_params,
    ;
    "${matrix_domain} admin API":
      location       => '/_synapse/admin',
      proxy          => 'http://synapse_main',
      location_allow => ['127.0.0.1', '10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16'],
      location_deny  => ['all'],
    ;
    "${matrix_domain} media":
      location => '~ ^/_matrix/media/',
      proxy    => 'http://synapse_media',
    ;
    "${matrix_domain} client sync":
      location           => '~ ^/_matrix/client/.*/sync$',
      proxy              => 'http://synapse_media',
      proxy_read_timeout => '60s',
    ;
    "${matrix_domain} client paths":
      location => '~ ^/_matrix/client/.*/(user|rooms/.*/initialSync)',
      proxy    => 'http://synapse_media',
    ;
    "${matrix_domain} federation":
      location => '/_matrix/federation/',
      proxy    => 'http://synapse_federation',
    ;
    "${matrix_domain} key":
      location => '/_matrix/key/',
      proxy    => 'http://synapse_federation',
    ;
    "${matrix_domain} client":
      location => '/_matrix/client/',
      proxy    => 'http://synapse_client',
    ;
    "${matrix_domain} fallback":
      location => '/_matrix/',
      proxy    => 'http://synapse_main',
    ;
  }
}
