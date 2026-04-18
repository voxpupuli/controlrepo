# @summary Configures an nginx server to present the files under /var/mirror
#
# Configures an nginx server to present the files under /var/mirror. This class
# takes two puppet runs to fully apply because the needed certificates from
# Let's Encrypt are obtained during the first run and utilized in subsequent
# runs.
#
# @api private
#
class profiles::download_server::nginx {
  assert_private()

  class { 'nginx':
    server_purge         => true,
    confd_purge          => true,
    service_config_check => true,
  }

  $_server_names = $profiles::download_server::server_names

  $_server_names.keys().each |$domain| {
    # During the first puppet run for a new domain the certificate will not yet exist.
    # This conditional makes it so that the bits that rely on the certificate files
    # existing are not appled until after the cert has been issued and installed.
    # The result is that on the second puppet run all the SSL/TLS related bits
    # get applied to Nginx.
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

    $_server_names_array = $_server_names[$domain]['aliases'] ? {
      undef   => [$domain],
      default => [$domain] + $_server_names[$domain]['aliases']
    }

    nginx::resource::server { $domain:
      listen_port          => 80,
      server_name          => $_server_names_array,
      ipv6_enable          => true,
      ipv6_listen_options  => ' ', # when using IPv4 & IPv6 the default options break Nginx
      http2                => 'on',
      access_log           => "/var/log/nginx/${domain}.access.log",
      error_log            => "/var/log/nginx/${domain}.error.log",
      format_log           => 'combined',
      use_default_location => false,
      index_files          => [],
      *                    => $ssl,
    }

    nginx::resource::location { "${domain} Let's Encrypt challenges":
      location    => '^~ /.well-known/acme-challenge/',
      server      => $domain,
      www_root    => '/var/lib/letsencrypt/',
      index_files => [],
    }

    nginx::resource::location { "${domain} acme-challenge directory":
      location            => '= /.well-known/acme-challenge/',
      server              => $domain,
      location_cfg_append => { 'return' => '404', },
      index_files         => [],
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

    # This conditional keeps location blocks that rely on SSL/TLS bits being in place
    # are not appled before the certificates have been issued.
    if fact("letsencrypt_directory.\"${domain}\"") {
      $_server_names[$domain]['locations'].each |$orig_path, $settings| {
        nginx::resource::location { "${domain} ${orig_path}":
          ensure      => present,
          location    => $orig_path,
          ssl         => true,
          server      => $domain,
          index_files => [],
          *           => $settings,
        }
      }
    }
  }
}
