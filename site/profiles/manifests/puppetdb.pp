#
# @summary installs puppetdb
#
class profiles::puppetdb {
  require profiles::postgresql
  class { 'puppetdb':
    manage_dbserver => false,
    manage_firewall => false,
  }
  contain puppetdb
  class { 'puppetdb::master::config':
  }
  contain puppetdb::master::config
}
