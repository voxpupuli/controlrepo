#
# @summary configures puppetmodule.info
#
# @param domain the url to the site *without www*
# @param postgresql_password the database password
# @param postgresql_database the database name
# @param postgresql_user the database user
#
# @author Tim Meusel <tim@bastelfreak.de>
#
# @see https://puppetmodule.info
# @see https://github.com/puma/puma/blob/master/docs/nginx.md
#
class profiles::puppetmodule (
  Stdlib::Fqdn $domain = 'puppetmodule.info',
  Variant[String[1],Sensitive] $postgresql_password = 'oehr384yhg034y5oreihu04y5',
  String[1] $postgresql_user = 'puppetmodule',
  String[1] $postgresql_database = $postgresql_user,
) {
  # setup database
  require profiles::postgresql
  postgresql::server::db { $postgresql_database:
    user     => $postgresql_user,
    password => postgresql::postgresql_password($postgresql_user, $postgresql_password),
  }
  postgresql_conn_validator { 'validate postgres connection for puppetmodule.info':
    host        => '127.0.0.1',
    port        => 5432,
    db_username => $postgresql_user,
    db_password => $postgresql_password,
    db_name     => $postgresql_database,
    psql_path   => '/usr/bin/psql',
    before      => Service['puppetmodule.service'],
  }
  # setup all the webfoo
  require profiles::nginx
  profiles::certbot::nginx { $domain: }
  profiles::certbot::nginx { "www.${domain}": }
  # generate the cert
  # certbot certonly --webroot --webroot-path=/var/lib/letsencrypt/ --renew-by-default --keep --agree-tos --email tim@bastelfreak.de --key-type ecdsa  --elliptic-curve secp384r1 --non-interactive --text -d puppetmodule.info -d www.puppetmodule.info
  if fact('letsencrypt_directory."puppetmodule.info"') {
    nginx::resource::server { $domain:
      listen_ip              => $facts['networking']['ip'],
      ipv6_listen_ip         => $facts['networking']['ip6'],
      ipv6_enable            => true,
      ipv6_listen_options    => '',
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
      listen_ip           => $facts['networking']['ip'],
      ipv6_listen_ip      => $facts['networking']['ip6'],
      ipv6_enable         => true,
      ipv6_listen_options => '',
      ssl_redirect        => true,
      server_name         => [$domain],
    }
  }
  # Setup user and code
  group { 'puppetmodule':
    ensure => 'present',
    gid    => 51,
    system => true,
  }
  user { 'puppetmodule':
    ensure         => 'present',
    managehome     => true,
    purge_ssh_keys => true,
    uid            => 51,
    system         => true,
    require        => Group['puppetmodule'],
    home           => '/srv/puppetmodule',
    groups         => 'rvm',
  }
  # Puppet creates the home for us, but we need to update the mode, so nginx can access it
  file { '/srv/puppetmodule':
    ensure => 'directory',
    owner  => 'puppetmodule',
    group  => 'puppetmodule',
    mode   => '0755',
  }
  # that user runs nginx on Ubuntu
  user { $nginx::daemon_user:
    groups => ['puppetmodule'],
  }

  package { ['ruby', 'ruby-bundler', 'ruby-dev', 'libpq-dev']:
    ensure => 'installed',
  }
  -> exec { 'install deps':
    command     => 'bundle install --path .vendor/ --jobs 8',
    provider    => 'shell',
    cwd         => '/srv/puppetmodule/puppetmodule.info',
    require     => Vcsrepo['/srv/puppetmodule/puppetmodule.info'],
    refreshonly => true,
    user        => 'puppetmodule',
    environment => ['HOME=/srv/puppetmodule/'],
  }
  vcsrepo { '/srv/puppetmodule/puppetmodule.info':
    ensure             => 'present',
    provider           => 'git',
    source             => 'https://github.com/voxpupuli/puppetmodule.info.git',
    user               => 'puppetmodule',
    require            => User['puppetmodule'],
    keep_local_changes => true,
    notify             => Exec['install deps'],
  }
  -> file { '/srv/puppetmodule/puppetmodule.info/sockets':
    ensure => 'directory',
    owner  => 'puppetmodule',
    group  => 'puppetmodule',
  }

  systemd::unit_file { 'puppetmodule.socket':
    enable  => true,
    active  => true,
    content => file("${module_name}/puppetmodule.socket"),
    require => File['/srv/puppetmodule/puppetmodule.info/sockets'],
  }
  -> systemd::unit_file { 'puppetmodule.service':
    enable  => true,
    active  => true,
    content => file("${module_name}/puppetmodule.service"),
    require => File['/srv/puppetmodule/puppetmodule.info/sockets'],
  }
  systemd::timer { 'puppetmodule-hourly.timer':
    active          => true,
    enable          => true,
    timer_content   => file("${module_name}/puppetmodule-hourly.timer"),
    service_content => file("${module_name}/puppetmodule-hourly.service"),
  }
  systemd::timer { 'puppetmodule-daily.timer':
    active          => true,
    enable          => true,
    timer_content   => file("${module_name}/puppetmodule-daily.timer"),
    service_content => file("${module_name}/puppetmodule-daily.service"),
  }
}
