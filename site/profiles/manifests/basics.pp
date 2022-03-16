#
# @summary ssh profile to manage basic stuff that doesn't fit into a dedicated profile
#
# @author Tim Meusel <tim@bastelfreak.de>
#
class profiles::basics {

  # do a pluginsync in agentless setup
  # lint:ignore:puppet_url_without_modules
  file { $::settings::libdir:
    ensure  => directory,
    source  => 'puppet:///plugins',
    recurse => true,
    purge   => true,
    backup  => false,
    noop    => false,
  }
  # lint:endignore

  package { ['make', 'gcc', 'build-essential']:
    ensure => 'installed',
  }
}
