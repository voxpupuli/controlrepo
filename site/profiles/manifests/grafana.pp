#
# @summary installs grafana to display stats from dropsonde about Vox Pupuli modules
#
# @param postgresql_password
# @param postgresql_user
# @param postgresql_database
#
# @see https://dev.to/puppet/help-us-understand-how-you-use-open-source-puppet-51aj
# @see https://grafana.com/tutorials/run-grafana-behind-a-proxy/
#
# @author Tim Meusel <tim@bastelfreak.de>
#
class profiles::grafana (
  Variant[String[1],Sensitive] $postgresql_password = '023745uoehr98325yrsehrw023y4',
  String[1] $postgresql_user = 'grafana',
  String[1] $postgresql_database = $postgresql_user,
) {
  $domain = "grafana.${facts['networking']['fqdn']}"
  require profiles::nginx
  require profiles::certbot
  require profiles::postgresql
  require profiles::postfix
  package { 'toml':
    ensure   => 'installed',
    provider => 'puppet_gem',
  }
  postgresql::server::db { $postgresql_database:
    user     => $postgresql_user,
    password => postgresql::postgresql_password($postgresql_user, $postgresql_password),
  }
  postgresql_conn_validator { 'validate my postgres connection':
    host        => '127.0.0.1',
    port        => 5432,
    db_username => $postgresql_user,
    db_password => $postgresql_password,
    db_name     => $postgresql_database,
    psql_path   => '/usr/bin/psql',
    before      => Service['grafana'],
  }
  class { 'grafana':
    install_method => 'repo',
    cfg            => {
      server           => {
        http_addr => '127.0.0.1',
        http_port => 3001,
        domain    => $domain,
      },
      security         => {
        disable_gravatar => true,
      },
      analytics        => {
        reporting_enabled => false,
        check_for_updates => false,
      },
      # wait with TLS setup until we've proper puppet certificates
      database         => {
        type     => 'postgres',
        host     => '127.0.0.1',
        port     => 5432,
        user     => $postgresql_user,
        password => $postgresql_password,
      },
      smtp             => {
        enabled => true,
      },
      'auth.anonymous' => {
        enabled      => true,
        hide_version => true,
        org_name     => 'Vox Pupuli',
        org_role     => 'Viewer',
      },
    },
    require        => Package['toml'],
  }
  contain grafana
  grafana_plugin { 'grafana-bigquery-datasource':
    ensure => 'present',
  }

  # setup vhost
  # how to get a cert
  # certbot certonly --webroot --email pmc@voxpupuli.org --rsa-key-size 4096 --domain grafana.voxpupu.li \
  # --webroot-path=/var/lib/letsencrypt/ --renew-by-default --keep --agree-tos --text --non-interactive
  if fact('letsencrypt_directory."grafana.voxpupu.li"') {
    $path = fact('letsencrypt_directory."grafana.voxpupu.li"')
    $ssl = {
      ssl_key      => "${path}/privkey.pem",
      ssl_cert     => "${path}/fullchain.pem",
      ssl          => true,
      ssl_redirect => true,
    }
  } else {
    $ssl = {}
  }
  nginx::resource::server { $domain:
    listen_port         => 80,
    proxy               => 'http://127.0.0.1:3001',
    server_name         => [$domain, 'grafana.puppet.community', 'grafana.voxpupuli.org'],
    proxy_http_version  => '1.1',
    ipv6_enable         => true,
    http2               => 'on',
    ipv6_listen_options => '',
    add_header          => {
      'X-Frame-Options'         => 'DENY',
      'Content-Security-Policy' => "upgrade-insecure-requests; default-src 'none'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline' blob:; img-src 'self' data: grafana.com; connect-src 'self' grafana.com; font-src 'self'; object-src 'none'; media-src 'none'; worker-src 'none'; frame-src 'none'; form-action 'self'; frame-ancestors 'none'; base-uri 'self';",
    },
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
  if fact('letsencrypt_directory."grafana.voxpupu.li"') {
    nginx::resource::location { '/api/live':
      server             => $domain,
      rewrite_rules      => ['^/(.*)  /$1 break'],
      proxy_http_version => '1.1',
      proxy_set_header   => [
        'Host $http_host',
        'X-Real-IP $remote_addr',
        'X-Forwarded-For $proxy_add_x_forwarded_for',
        'X-Forwarded-Proto $scheme',
        'X-Forwarded-Ssl on',
        'Proxy ""',
        'Upgrade $http_upgrade',
        'Connection $connection_upgrade',
      ],
      proxy              => 'http://127.0.0.1:3001',
      ssl                => true,
      ssl_only           => true,
    }
  }
  nginx::resource::map { 'connection_upgrade':
    string   => '$http_upgrade',
    mappings => {
      'default' => 'upgrade',
      "''"      => 'close',
    },
  }
  nginx::resource::location { '^~ /.well-known/acme-challenge/':
    server      => $domain,
    www_root    => '/var/lib/letsencrypt/',
    index_files => [],
  }
  nginx::resource::location { '= /.well-known/acme-challenge/':
    server              => $domain,
    location_cfg_append => { 'return' => '404', },
    index_files         => [],
  }
}
