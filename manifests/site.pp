## pluginsync
file { $::settings::libdir: # lint:ignore:top_scope_facts
  ensure  => directory,
  source  => 'puppet:///plugins', # lint:ignore:puppet_url_without_modules
  recurse => true,
  purge   => true,
  backup  => false,
  noop    => false,
}

# make sure EVERY node gets baseline settings, even if it doesn't yet have a role
contain profiles::base

# Look in Hiera for the role to be included. This method will only permit a
# single role to be assigned to a node.
$_node_role = lookup('role', String, 'first', '')
unless empty($_node_role) {
  include($_node_role)
}
