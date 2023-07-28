#
# @summary installs puppetdb
#
class profiles::puppetdb {
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
  #class { 'puppetdb::master::config':
  #}
  #contain puppetdb::master::config
  #class { 'puppetdb::server':
  #  manage_firewall => false,
  #}
  #contain puppetdb::server
  class { 'puppet::server::puppetdb':
    server => 'puppetserver.voxpupuli.org',
  }
  contain puppet::server::puppetdb
}
