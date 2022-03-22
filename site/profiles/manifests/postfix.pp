#
# @summary installs postfix
#
class profiles::postfix {
  # provides /etc/ssl/certs/ca-certificates.crt for smtpd_tls_CAfile ini_setting
  require profiles::base
  # todo: use puppet/postfix
  package { 'postfix':
    ensure => 'installed',
  }
  -> service { 'postfix.service':
    ensure => 'running',
    enable => true,
  }
  if fact('letsencrypt_directory."grafana.voxpupu.li"') {
    $path = fact('letsencrypt_directory."grafana.voxpupu.li"')
    ini_setting { 'smtpd_tls_cert_file':
      ensure  => 'present',
      path    => '/etc/postfix/main.cf',
      section => '',
      setting => 'smtpd_tls_cert_file',
      value   => "${path}/fullchain.pem",
      notify  => Service['postfix.service'],
    }
    ini_setting { 'smtpd_tls_key_file':
      ensure  => 'present',
      path    => '/etc/postfix/main.cf',
      section => '',
      setting => 'smtpd_tls_key_file',
      value   => "${path}/privkey.pem",
      notify  => Service['postfix.service'],
    }
    ini_setting { 'smtpd_tls_CAfile':
      ensure  => 'present',
      path    => '/etc/postfix/main.cf',
      section => '',
      setting => 'smtpd_tls_CAfile',
      value   => '/etc/ssl/certs/ca-certificates.crt',
      notify  => Service['postfix.service'],
    }
  }
}
