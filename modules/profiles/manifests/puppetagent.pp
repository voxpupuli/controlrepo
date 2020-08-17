class profiles::puppetagent {

  contain puppet

  # If this is an AIO setup, puppet uses a vendored ruby
  # we don't care about the value of the fact, we only want to know if it is present
  # msgpack will be used by the agent for connections to the server
  if fact('aio_agent_version') {
    package { 'msgpack':
      ensure   => 'present',
      provider => 'puppet_gem',
      require  => Package['puppet-agent'],
    }
  }
}
