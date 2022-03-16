#
# @summary ssh profile to manage basic stuff that doesn't fit into a dedicated profile
#
# @author Tim Meusel <tim@bastelfreak.de>
#
class profiles::base {
  package { ['make', 'gcc', 'build-essential', 'htop', 'lsb-release']:
    ensure => 'installed',
  }
}
