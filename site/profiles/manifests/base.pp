#
# @summary ssh profile to manage basic stuff that doesn't fit into a dedicated profile
#
# @author Tim Meusel <tim@bastelfreak.de>
#
class profiles::base {
  package { ['make', 'gcc', 'build-essential', 'htop', 'lsb-release', 'ctop', 'ca-certificates', 'apt-file']:
    ensure => 'installed',
  }
  exec { 'refresh apt-file cache':
    refreshonly => true,
    command     => '/usr/bin/apt-file update',
    subscribe   => Package['apt-file'],
  }
  package { 'snapd':
    ensure => 'absent',
  }
}
