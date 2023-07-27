#
# @summary configures redis on different platforms
#
class profiles::redis {
  if $facts['os']['name'] == 'Archlinux' {
    fail('profiles::redis does not work on Archlinux, because puppet/redis does not support Archlinux')
  }
  # manage_repo pulls in the epel module, but that's broken on CentOS 8
  # https://github.com/voxpupuli/puppet-epel/issues/108
  elsif $facts['os']['family'] == 'RedHat' {
    $params  = { 'require' => Package['epel-release'], 'manage_repo' => false }
    require profiles::centos
  } elsif $facts['os']['family'] == 'Debian' {
    $params = { 'redis_apt_repo' => true, 'manage_repo' => true }
  } else {
    $params  = {}
  }
  class { 'redis':
    * => $params,
  }
  contain redis
}
