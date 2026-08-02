#
# @summary deploys our website
#
# @author Tim Meusel <tim@bastelfreak.de>
#
class profiles::openvoxproject {
  $domain = 'staging.openvoxproject.org'
  profiles::certbot::nginx { $domain: }
  # generate the cert
  if fact('letsencrypt_directory."staging.openvoxproject.org"') {
    nginx::resource::server { $domain:
      listen_ip              => '65.109.240.83',
      ipv6_listen_ip         => '2a01:4f9:c01f:6a::1',
      ipv6_enable            => true,
      ipv6_listen_options    => ' ',
      server_name            => [$domain],
      ssl                    => true,
      ssl_cert               => "/etc/letsencrypt/live/${domain}/fullchain.pem",
      ssl_key                => "/etc/letsencrypt/live/${domain}/privkey.pem",
      ssl_redirect           => true,
      proxy                  => 'http://127.0.0.1:8080',
      proxy_http_version     => '1.1',
      rewrite_www_to_non_www => false,
      use_default_location   => true,
      index_files            => [],
      http2                  => 'on',
      add_header             => {
        'Strict-Transport-Security' => {
          'max-age=63072000' => 'always',
        },
      },
    }
  } else {
    nginx::resource::server { $domain:
      listen_ip              => '65.109.240.83',
      ipv6_listen_ip         => '2a01:4f9:c01f:6a::1',
      ipv6_enable            => true,
      ipv6_listen_options    => ' ',
      ssl_redirect           => true,
      server_name            => [$domain],
      rewrite_www_to_non_www => false, # change later
      http2                  => 'on',
    }
  }
  letsencrypt::certonly { $domain:
    domains         => [$domain],
    plugin          => 'nginx',
    manage_cron     => false,
    additional_args => [
      '--no-redirect',
    ],
    require         => [
      Nginx::Resource::Server[$domain],
    ],
  }
}
