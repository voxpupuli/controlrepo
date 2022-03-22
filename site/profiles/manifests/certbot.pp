#
# @summary configures the certbot foo. Doesn't create certificates!
#
# @author Tim Meusel <tim@bastelfreak.de>
class profiles::certbot {
  package { 'certbot':
    ensure => 'installed',
  }
  service { 'certbot.timer':
    ensure  => 'running',
    enable  => true,
    require => Package['certbot'],
  }
  systemd::dropin_file { 'verbose.conf':
    unit    => 'certbot.service',
    content => file("${module_name}/certbot.service"),
    require => Package['certbot'],
    notify  => Service['certbot.timer'],
  }
}
