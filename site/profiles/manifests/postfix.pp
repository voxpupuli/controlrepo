#
# @summary installs postfix
#
class profiles::postfix {
  # todo: use puppet/postfix
  package { 'postfix':
    ensure => 'installed',
  }
  -> service { 'postfix':
    ensure => 'running',
    enable => true,
  }
}
