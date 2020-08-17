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
