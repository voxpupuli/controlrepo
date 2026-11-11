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
    # The delegation payloads — the entire purpose of this vhost. The
    # expected values are documented in homeserver.yaml.epp; empty files
    # here break both federation and client discovery for the whole
    # server_name.
    "${root}/.well-known/matrix/server":
      ensure  => 'file',
      content => "{\"m.server\": \"${matrix_domain}:443\"}\n",
    ;
    "${root}/.well-known/matrix/client":
      ensure  => 'file',
      content => "{\"m.homeserver\": {\"base_url\": \"https://${matrix_domain}\"}}\n",
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
    # nginx allows listen options on only one [::]:80 listener; the
    # matrix vhost carries them. The module's default would emit
    # ipv6only=on here too ("duplicate listen options"), and its v8
    # types reject '' — a single space renders as no options.
    ipv6_listen_options  => ' ',
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
  # Member hash keys become resource titles and must be globally unique
  # across all upstreams (the address comes from server/port), hence the
  # per-upstream prefixes.
  nginx::resource::upstream {
    'synapse_client':
      members => {
        'client-worker1' => { server => '127.0.0.1', port => 8081 },
        'client-worker2' => { server => '127.0.0.1', port => 8082 },
      };
    'synapse_federation':
      members => {
        'federation-worker1' => { server => '127.0.0.1', port => 8081 },
        'federation-worker2' => { server => '127.0.0.1', port => 8082 },
        'federation-worker3' => { server => '127.0.0.1', port => 8083 },
      };
    'synapse_media':
      members => {
        'media-worker4' => { server => '127.0.0.1', port => 8084 },
      };
    'synapse_stream_writer':
      members => {
        'stream-writer' => { server => '127.0.0.1', port => 8086 },
      };
    'synapse_main':
      members => {
        'main' => { server => '127.0.0.1', port => 8008 },
      };
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
    "${domain} matrix well-known":
      server              => $domain,
      location            => '^~ /.well-known/matrix/',
      www_root            => $root,
      # Client discovery is done by browsers cross-origin; both files
      # must be JSON regardless of file extension.
      location_cfg_append => {
        'default_type' => 'application/json',
        'add_header'   => "'Access-Control-Allow-Origin' '*' always",
      },
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
  $proxy_params = [
    'X-Forwarded-For $remote_addr',
    'X-Forwarded-Proto $scheme',
    'Host $host',
  ]

  # Which process serves a client endpoint follows the Synapse worker
  # docs (docs/workers.md at the version pinned in Dockerfile.synapse).
  # Their endpoint lists are allowlists: a generic worker answers 404 for
  # anything not listed, and an endpoint that writes to a stream raises
  # on every process except that stream's writer. So the catch-all for
  # /_matrix/client/ is the main process, and only the listed endpoints
  # go to workers. The two arrays are copied from the docs verbatim so
  # they can be diffed against them on a Synapse upgrade.

  # "The following endpoints should be routed directly to the worker
  # configured as the stream writer" for typing, to_device, account_data
  # and receipts: all four are written by receipts_writer (see
  # stream_writers in homeserver.yaml.epp).
  $stream_writer_endpoints = [
    '^/_matrix/client/(api/v1|r0|v3|unstable)/rooms/.*/typing',
    '^/_matrix/client/(r0|v3|unstable)/sendToDevice/',
    '^/_matrix/client/(r0|v3|unstable)/.*/tags',
    '^/_matrix/client/(r0|v3|unstable)/.*/account_data',
    '^/_matrix/client/(r0|v3|unstable)/rooms/.*/receipt',
    '^/_matrix/client/(r0|v3|unstable)/rooms/.*/read_markers',
  ]

  # synapse.app.generic_worker "Client API", "Encryption",
  # "Registration/login", "Event sending" and "User directory" requests.
  # Left on the main process on purpose: /sync (own locations below),
  # /messages (all requests for a room must reach the same instance),
  # the SSO endpoints (no SSO is configured), the unstable MSC endpoints
  # and the ones workers only serve for GET (pushrules, presence).
  $client_worker_endpoints = [
    '^/_matrix/client/(api/v1|r0|v3|unstable)/createRoom$',
    '^/_matrix/client/(api/v1|r0|v3|unstable)/publicRooms$',
    '^/_matrix/client/(api/v1|r0|v3|unstable)/rooms/.*/joined_members$',
    '^/_matrix/client/(api/v1|r0|v3|unstable)/rooms/.*/context/.*$',
    '^/_matrix/client/(api/v1|r0|v3|unstable)/rooms/.*/members$',
    '^/_matrix/client/(api/v1|r0|v3|unstable)/rooms/.*/state$',
    '^/_matrix/client/v1/rooms/.*/hierarchy$',
    '^/_matrix/client/(v1|unstable)/rooms/.*/relations/',
    '^/_matrix/client/v1/rooms/.*/threads$',
    '^/_matrix/client/unstable/im.nheko.summary/summary/.*$',
    '^/_matrix/client/v1/room_summary/.*$',
    '^/_matrix/client/(r0|v3|unstable)/account/3pid$',
    '^/_matrix/client/(r0|v3|unstable)/account/whoami$',
    '^/_matrix/client/(r0|v3|unstable)/account/deactivate$',
    '^/_matrix/client/(r0|v3)/delete_devices$',
    '^/_matrix/client/(api/v1|r0|v3|unstable)/devices(/|$)',
    '^/_matrix/client/versions$',
    '^/_matrix/client/(api/v1|r0|v3|unstable)/voip/turnServer$',
    '^/_matrix/client/(api/v1|r0|v3|unstable)/rooms/.*/event/',
    '^/_matrix/client/(api/v1|r0|v3|unstable)/joined_rooms$',
    '^/_matrix/client/v1/rooms/.*/timestamp_to_event$',
    '^/_matrix/client/(api/v1|r0|v3|unstable/.*)/rooms/.*/aliases',
    '^/_matrix/client/(api/v1|r0|v3|unstable)/search$',
    '^/_matrix/client/(r0|v3|unstable)/user/.*/filter(/|$)',
    '^/_matrix/client/(api/v1|r0|v3|unstable)/directory/room/.*$',
    '^/_matrix/client/(r0|v3|unstable)/capabilities$',
    '^/_matrix/client/(r0|v3|unstable)/notifications$',
    '^/_matrix/client/(r0|v3|unstable)/keys/query$',
    '^/_matrix/client/(r0|v3|unstable)/keys/changes$',
    '^/_matrix/client/(r0|v3|unstable)/keys/claim$',
    '^/_matrix/client/(r0|v3|unstable)/room_keys/',
    '^/_matrix/client/(r0|v3|unstable)/keys/upload',
    '^/_matrix/client/(api/v1|r0|v3|unstable)/keys/device_signing/upload$',
    '^/_matrix/client/(api/v1|r0|v3|unstable)/keys/signatures/upload$',
    '^/_matrix/client/(api/v1|r0|v3|unstable)/login$',
    '^/_matrix/client/(r0|v3|unstable)/register$',
    '^/_matrix/client/(r0|v3|unstable)/register/available$',
    '^/_matrix/client/v1/register/m.login.registration_token/validity$',
    '^/_matrix/client/(r0|v3|unstable)/password_policy$',
    '^/_matrix/client/(api/v1|r0|v3|unstable)/rooms/.*/redact',
    '^/_matrix/client/(api/v1|r0|v3|unstable)/rooms/.*/send',
    '^/_matrix/client/(api/v1|r0|v3|unstable)/rooms/.*/state/',
    '^/_matrix/client/(api/v1|r0|v3|unstable)/rooms/.*/(join|invite|leave|ban|unban|kick)$',
    '^/_matrix/client/(api/v1|r0|v3|unstable)/join/',
    '^/_matrix/client/(api/v1|r0|v3|unstable)/knock/',
    '^/_matrix/client/(api/v1|r0|v3|unstable)/profile/',
    '^/_matrix/client/(r0|v3|unstable)/user_directory/search$',
  ]

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
    # Media: the legacy path plus the Matrix 1.11+ authenticated paths
    # (client and federation) — all served by the media worker.
    "${matrix_domain} media":
      location => '~ ^/_matrix/media/',
      proxy    => 'http://synapse_media',
    ;
    "${matrix_domain} authenticated client media":
      location => '~ ^/_matrix/client/v1/media/',
      proxy    => 'http://synapse_media',
    ;
    "${matrix_domain} authenticated federation media":
      location => '~ ^/_matrix/federation/v1/media/',
      proxy    => 'http://synapse_media',
    ;
    # Sync long-polls: the timeout is client-chosen (often >60s), so the
    # read timeout must be generous or nginx severs healthy polls.
    # worker4 is the designated sync+media worker (see homeserver.yaml
    # stream_writers/run_background_tasks_on), hence synapse_media.
    "${matrix_domain} client sync":
      location           => '~ ^/_matrix/client/(r0|v3)/sync$',
      proxy              => 'http://synapse_media',
      proxy_read_timeout => '600s',
    ;
    "${matrix_domain} client initial sync":
      location => '~ ^/_matrix/client/(api/v1|r0|v3)/(events|initialSync|rooms/[^/]+/initialSync)$',
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
    # nginx takes the first matching regex location in file order, and
    # the module orders by priority: the stream writer endpoints must win
    # over the broader worker patterns.
    "${matrix_domain} client stream writer":
      location => "~ (${stream_writer_endpoints.join('|')})",
      proxy    => 'http://synapse_stream_writer',
      priority => 450,
    ;
    "${matrix_domain} client workers":
      location => "~ (${client_worker_endpoints.join('|')})",
      proxy    => 'http://synapse_client',
    ;
    "${matrix_domain} client":
      location => '/_matrix/client/',
      proxy    => 'http://synapse_main',
    ;
    "${matrix_domain} fallback":
      location => '/_matrix/',
      proxy    => 'http://synapse_main',
    ;
  }
}
