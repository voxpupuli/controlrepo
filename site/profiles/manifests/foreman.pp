#
# @summary configure foreman + plugins
#
# @see `cat /opt/puppetlabs/puppet/cache/foreman_cache_data/admin_password` provides the admin password
#
class profiles::foreman {
  require profiles::redis
  require profiles::postgresql
  require profiles::nftables # ensures hkp access is working to download the apt key

  class { 'foreman::repo':
    repo => '3.11',
  }

  class { 'foreman':
    logging_type             => 'journald',
    initial_admin_username   => 'admin',
    initial_admin_first_name => 'Vox',
    initial_admin_last_name  => 'Pupuli',
    initial_admin_email      => 'pmc@voxpupuli.org',
    register_in_foreman      => true, # is a foreman 3.1+ feature
    rails_cache_store        => {
      'type'    => 'redis',
      'urls'    => ['localhost:6379/0'],
      'options' => {
        'compress'  => 'true',
        'namespace' => 'foreman',
      },
    },
  }
  $packages = $facts['os']['family'] ? {
    'RedHat' => ['rubygem-foreman_puppet', 'rubygem-puppetdb_foreman'],
    'Debian' => ['ruby-foreman-puppet', 'ruby-puppetdb-foreman'],
  }
  $packages.each |$package| {
    package { $package:
      ensure  => 'installed',
      require => Package['foreman-service'],
      notify  => Service['foreman'],
    }
  }
  class { 'foreman_proxy':
    register_in_foreman => true, # is a foreman 3.1+ feature
    puppet              => true,
    puppetca            => true,
    tftp                => false,
    dhcp                => false,
    dns                 => false,
    bmc                 => false,
    realm               => false,
  }
  # open http/https in firewall
  require nftables::rules::http
  require nftables::rules::https
}
