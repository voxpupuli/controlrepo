class profiles::basics {
  package { ['make', 'gcc', 'build-essential']:
    ensure => 'installed',
  }
}
