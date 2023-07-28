# hack pluginsync as file resource. only required for `puppet apply` usage
# this works by accident with puppet agent, but only on the puppetserver
# it breaks puppet agent on other systems, so we need to guard it
if $trusted['authenticated'] == 'local' {
  file { $settings::libdir:
    ensure  => directory,
    source  => 'puppet:///plugins', # lint:ignore:puppet_url_without_modules
    recurse => true,
    purge   => true,
    backup  => false,
    noop    => false,
    tags    => 'hacked_pluginsync',
  }
}

# include base profile that every node gets
contain profiles::base

# include node specific profiles
lookup('classes', Array[String[1]], 'unique', []).each |$c| {
  contain $c
}
