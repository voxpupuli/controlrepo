# include base profile that every node gets
contain profiles::base

## pluginsync
file { $::settings::libdir: # lint:ignore:top_scope_facts
  ensure  => directory,
  source  => 'puppet:///plugins', # lint:ignore:puppet_url_without_modules
  recurse => true,
  purge   => true,
  backup  => false,
  noop    => false,
}

# include node specific profiles
lookup('classes', Array[String[1]], 'unique', []).each |$c| {
  contain $c
}
