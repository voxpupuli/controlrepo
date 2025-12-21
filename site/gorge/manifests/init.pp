#
# @summary configures gorge
#
# @param version the version we want to install, or absent
#
# @see https://github.com/voxpupuli/gorge
#
class gorge (
  String[1] $version = '0.7.0',
) {
  group { 'gorge':
    ensure => 'present',
    system => true,
  }
  user { 'gorge':
    ensure         => 'present',
    system         => true,
    purge_ssh_keys => true,
    shell          => '/usr/sbin/nologin',
    home           => '/opt/gorge',
    managehome     => true,
  }

  package { 'gorge':
    ensure => 'installed',
    source => "https://github.com/voxpupuli/gorge/releases/download/0.7.0/gorge_${version}_linux_amd64.deb",
  }

  systemd::dropin_file { 'user.conf':
    unit    => 'gorge.service',
    content => "[Service]\nUser=gorge\nGroup=gorge\n",
    require => Package['gorge'],
  }
  systemd::dropin_file { 'start.conf':
    unit => 'gorge.service',
    content => "[Service]\nExecStart=\nExecStart=/usr/bin/gorge serve --import-proxied-releases --ui --cache-max-age 9999999999999999 --fallback-proxy https://forge.puppetlabs.com --cache-prefixes /v3/files,/v3/modules\n",
    require => Package['gorge'],
  }
  service { 'gorge.service':
    ensure => 'running',
    enable => true,
    require => User['gorge'],
  }
}
