# @summary configure puppet agent and server
#
# @param server decide if the server should be configured as well
# @param manage_msgpack configure if we should install msgpack on the agent
#
# @author Tim Meusel <tim@bastelfreak.de>
#
class profiles::puppet (
  Boolean $server = ($trusted['pp_role'] == 'puppetserver'),
  Boolean $manage_msgpack = ($facts['os']['name'] != 'gentoo'),
) {
  include profiles::puppetcode
  if $server {
    require profiles::foreman
    include profiles::puppetdb
    $params = {
      server                     => true,
      #server_reports             => 'puppetdb,foreman',
      server_storeconfigs        => true,
      server_foreman             => true,
      # don't create /etc/puppetlabs/code/environments/common
      server_common_modules_path => [],
      server_jvm_min_heap_size   => '1G',
      server_jvm_max_heap_size   => '1G',
      #server_jvm_extra_args      => ['-Djruby.logger.class=com.puppetlabs.jruby_utils.jruby.Slf4jLogger', '-XX:+UseParallelGC'],
      server_multithreaded       => true,
    }
    package { 'msgpack-server':
      ensure   => 'installed',
      provider => 'puppetserver_gem',
      name     => 'msgpack',
      require  => [Package['make'],Package['gcc'],Class['puppet']],
    }
    contain profiles::puppetserver_firewalling
  } else {
    $params = {}
  }
  class { 'puppet':
    runmode              => 'unmanaged',
    unavailable_runmodes => ['cron', 'systemd.timer'],
    *                    => $params,
  }
  if $manage_msgpack {
    if $facts['os']['name'] == 'Archlinux' {
      $provider = undef
      $package = 'ruby-msgpack'
    } else {
      $provider = 'puppet_gem'
      $package = 'msgpack'
    }
    package { $package:
      ensure   => 'installed',
      provider => $provider,
      require  => Class['puppet'],
    }
  }
}
