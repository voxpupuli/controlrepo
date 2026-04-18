class profiles::openvox {
  $domain = 'openvoxproject.org'
  profiles::certbot::nginx { $domain: }
  profiles::certbot::nginx { "www.${domain}": }
  # generate the cert
  if fact('letsencrypt_directory."openvoxproject.org"') {
    nginx::resource::server { $domain:
      listen_ip              => '5.75.218.154',
      ipv6_listen_ip         => '2a01:4f8:1c17:b00c::1',
      ipv6_enable            => true,
      ipv6_listen_options    => ' ',
      server_name            => [$domain],
      ssl                    => true,
      ssl_cert               => "/etc/letsencrypt/live/${domain}/fullchain.pem",
      ssl_key                => "/etc/letsencrypt/live/${domain}/privkey.pem",
      ssl_redirect           => true,
      proxy                  => 'http://127.0.0.1:8080',
      proxy_http_version     => '1.1',
      rewrite_non_www_to_www => true,
    }
  } else {
    nginx::resource::server { $domain:
      listen_ip           => '5.75.218.154',
      ipv6_listen_ip      => '2a01:4f8:1c17:b00c::1',
      ipv6_enable         => true,
      ipv6_listen_options => ' ',
      ssl_redirect        => true,
      server_name         => [$domain],
    }
  }
  letsencrypt::certonly { $domain:
    domains         => [$domain, "www.${domain}"],
    plugin          => 'nginx',
    manage_cron     => false,
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
