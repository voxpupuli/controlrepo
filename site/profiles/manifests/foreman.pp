#
# @summary configure foreman + plugins
#
# @see `cat /opt/puppetlabs/puppet/cache/foreman_cache_data/admin_password` provides the admin password
#
class profiles::foreman {
  require profiles::redis
  require profiles::postgresql
  require profiles::nftables # ensures hkp access is working to download the apt key
  # this pulls in postgresql:12 as module
  # https://github.com/theforeman/foreman-packaging/blob/61cdf829ea481294d8d00dc6162e3524875ebb2d/modulemd/modulemd-foreman-el8.yaml#L27-L28
  #class { 'foreman::repo':
  #  repo => '3.3',
  #}

  #foreman::repos { 'foreman':
  #  repo             => '3.7',
  #  gpgcheck         => true,
  #  yum_repo_baseurl => 'https://deb.theforeman.org',
  #  before           => [Class['foreman'], Class['foreman_proxy'],],
  #}
  class { 'foreman::repo':
    repo => '3.7',
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
