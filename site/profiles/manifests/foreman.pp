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
    repo => '3.17',
  }

  class { 'foreman':
    foreman_service_puma_workers     => 3,
    foreman_service_puma_threads_min => 3,
    foreman_service_puma_threads_max => 3,
    logging_type                     => 'journald',
    initial_admin_username           => 'admin',
    initial_admin_first_name         => 'Vox',
    initial_admin_last_name          => 'Pupuli',
    initial_admin_email              => 'pmc@voxpupuli.org',
    register_in_foreman              => true, # is a foreman 3.1+ feature
    rails_cache_store                => {
      'type'    => 'redis',
      'urls'    => ['localhost:6379/0'],
      'options' => {
        'compress'  => 'true',
        'namespace' => 'foreman',
      },
    },
  }
  include foreman::plugin::puppet
  include foreman::plugin::puppetdb
  include foreman::plugin::tasks
  include foreman::plugin::remote_execution
  include foreman::plugin::openbolt
  include foreman::plugin::hdm

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
  include foreman_proxy::plugin::remote_execution::script
  include foreman_proxy::plugin::openbolt

  # open http/https in firewall
  require nftables::rules::http
  require nftables::rules::https

  # migrate to puppet/bolt as soon as it's updated
  package { 'openbolt':
    ensure => 'installed',
  }

  # setup ssh defaults for openbolt
  ssh::client::config::user { 'foreman-proxy-bolt':
    ensure              => present,
    user                => 'foreman-proxy',
    user_home_dir       => '/usr/share/foreman-proxy',
    manage_user_ssh_dir => false,
    options             => {
      'Host *' => {
        'IdentityFile' => '~/.ssh/id_rsa_foreman_proxy',
        'User'         => 'root',
      },
    },
    require             => Class['foreman_proxy::plugin::remote_execution::script'], # creates ~/.ssh/id_rsa_foreman_proxy
  }
}
