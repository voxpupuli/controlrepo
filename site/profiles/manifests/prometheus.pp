#
# @summary install Prometheus
#
class profiles::prometheus {
  class { 'prometheus':
    version                  => '2.39.1',
    web_listen_address       => '127.0.0.1:9090',
    manage_prometheus_server => true,
  }
  require profiles::nginx
  require profiles::certbot

  # setup vhost
  # how to get a cert
  # certbot certonly --webroot --email pmc@voxpupuli.org --rsa-key-size 4096 --domain prometheus.voxpupu.li \
  # --webroot-path=/var/lib/letsencrypt/ --renew-by-default --keep --agree-tos --text --non-interactive
  $domain = 'prometheus.voxpupu.li'
  if fact('letsencrypt_directory."prometheus.voxpupu.li"') {
    $path = fact('letsencrypt_directory."prometheus.voxpupu.li"')
    $ssl = {
      ssl_key      => "${path}/privkey.pem",
      ssl_cert     => "${path}/fullchain.pem",
      ssl          => true,
      ssl_redirect => true,
    }
    $ssl_location = true
  } else {
    $ssl = {}
    $ssl_location = false
  }
  nginx::resource::server { $domain:
    listen_port         => 80,
    proxy               => 'http://127.0.0.1:9090',
    server_name         => [$domain, 'prometheus.puppet.community', 'prometheus.voxpupuli.org'],
    proxy_http_version  => '1.1',
    ipv6_enable         => true,
    http2               => 'on',
    ipv6_listen_options => '',
    proxy_set_header    => [
      'Host $host',
      'X-Real-IP $remote_addr',
      'X-Forwarded-For $proxy_add_x_forwarded_for',
      'X-Forwarded-Proto $scheme',
      'X-Forwarded-Ssl on',
      'Proxy ""',
    ],
    *                   => $ssl,
  }
  nginx::resource::location { "^~ /.well-known/acme-challenge/ - ${domain}":
    server      => $domain,
    www_root    => '/var/lib/letsencrypt/',
    index_files => [],
    location    => '^~ /.well-known/acme-challenge/',
    ssl         => $ssl_location,
  }
  nginx::resource::location { "= /.well-known/acme-challenge/ - ${domain}":
    server              => $domain,
    location_cfg_append => { 'return' => '404', },
    index_files         => [],
    location            => '= /.well-known/acme-challenge/',
    ssl                 => $ssl_location,
  }
}
