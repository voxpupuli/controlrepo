#
# @summary installs puppetdb *on a puppetserver that also runs foreman*
#
# @api private
#
# @author Tim Meusel <tim@bastelfreak.de>
#
class profiles::puppet::db {
  assert_private()
  require profiles::postgresql
  include postgresql::server::contrib
  postgresql::server::extension { 'pg_trgm':
    database => 'puppetdb',
    require  => Postgresql::Server::Db['puppetdb'],
    before   => Service['puppetdb'],
  }
  class { 'puppetdb':
    manage_dbserver => false,
    manage_firewall => false,
  }
  contain puppetdb
  class { 'puppet::server::puppetdb':
    server => $facts['networking']['fqdn'],
  }
  contain puppet::server::puppetdb
}
