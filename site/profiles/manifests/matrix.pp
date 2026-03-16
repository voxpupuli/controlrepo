class profiles::matrix {
  $domain = 'voxpupuli.party'
  $root = "/srv/${domain}"
  file { $root:
    ensure => 'directory',
  }
  file { "${root}/.well-known":
    ensure => 'directory',
  }
  file { "${root}/.well-known/matrix/":
    ensure => 'directory',
  }
  file { "${root}/.well-known/matrix/client":
    ensure => 'file',
  }
  file { "${root}/.well-known/matrix/server":
    ensure => 'file',
  }
  require nftables::rules::http
  require nftables::rules::https

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
    ipv6_listen_options  => '', # when using IPv4 & IPv6 the default options break Nginx
    http2                => 'on',
    access_log           => "/var/log/nginx/${domain}.access.log",
    error_log            => "/var/log/nginx/${domain}.error.log",
    format_log           => 'combined',
    use_default_location => false,
    index_files          => [],
    www_root             => $root,
    *                    => $ssl,
  }
  nginx::resource::location { "${domain} Let's Encrypt challenges":
    server      => $domain,
    www_root    => '/var/lib/letsencrypt/',
    index_files => [],
    location    => '^~ /.well-known/acme-challenge/',
  }
  nginx::resource::location { "${domain} acme-challenge directory":
    server              => $domain,
    location_cfg_append => { 'return' => '404', },
    index_files         => [],
    location            => '= /.well-known/acme-challenge/',
  }
  letsencrypt::certonly { $domain:
    domains         => [$domain],
    plugin          => 'nginx',
    manage_cron     => true,
    additional_args => [
      '--no-redirect',
    ],
    require         => [
      Nginx::Resource::Server[$domain],
      Nginx::Resource::Location[
        "${domain} Let's Encrypt challenges",
        "${domain} acme-challenge directory",
      ],
    ],
  }
}
