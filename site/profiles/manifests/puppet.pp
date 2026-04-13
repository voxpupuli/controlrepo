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
  # setup r10k for puppet apply, if we run with puppet apply
  if $trusted['authenticated'] == 'local' {
    include profiles::puppet::code
  }
  if $server {
    file { '/usr/local/bin/code-id-command.sh':
      ensure => 'file',
      source => 'puppet:///modules/profiles/code-id-command.sh',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }
    file { '/usr/local/bin/code-id-content.sh':
      ensure => 'file',
      source => 'puppet:///modules/profiles/code-id-content.sh',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }
    require profiles::foreman
    include profiles::puppet::db
    $params = {
      server                                 => true,
      server_versioned_code_id               => '/usr/local/bin/code-id-command.sh',
      server_versioned_code_content          => '/usr/local/bin/code-id-content.sh',
      server_reports                         => 'puppetdb,foreman',
      server_storeconfigs                    => true,
      server_foreman                         => true,
      # don't create /etc/puppetlabs/code/environments/common
      server_common_modules_path             => [],
      server_jvm_min_heap_size               => '1G',
      server_jvm_max_heap_size               => '1G',
      server_jvm_java_bin                    => '/usr/lib/jvm/java-21-openjdk-amd64/bin/java',
      #server_jvm_extra_args                 => ['-Djruby.logger.class=com.puppetlabs.jruby_utils.jruby.Slf4jLogger', '-XX:+UseParallelGC'],
      server_multithreaded                   => true,
      server_environment_class_cache_enabled => true,
      server_check_for_updates               => false,
      server_environment_timeout             => 'unlimited',
      server_strict_variables                => true,
      server_ca_allow_sans                   => true,
      server_ca_allow_auth_extensions        => true,
      server_ca_allow_auto_renewal           => true,
    }
    package { 'msgpack-server':
      ensure   => 'installed',
      provider => 'puppetserver_gem',
      name     => 'msgpack',
      require  => [Package['make'],Package['gcc'],Class['puppet']],
    }
    package { 'openjdk-21-jre-headless':
      ensure => 'installed',
      before => Service['puppetserver'],
    }
    contain profiles::puppet::server_firewalling
    file { '/usr/local/bin/r10k-postrun':
      content => file("${module_name}/r10k-postrun"),
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
    }
    class { 'r10k':
      pool_size       => $facts['processors']['count']*2,
      sources         => {
        'puppet' => {
          'remote'  => 'https://github.com/voxpupuli/controlrepo.git',
          'basedir' => '/etc/puppetlabs/code/environments',
        },
      },
      version         => '5.0.2',

      deploy_settings => {
        'generate_types' => true,
        'purge_levels'   => ['deployment'],
        'exclude_spec'   => true,
      },
      postrun         => [
        '/usr/local/bin/r10k-postrun',
        '$modifiedenvs',
      ],
    }
    contain r10k
    class { 'r10k::webhook':
      version => '2.14.3',
    }
  } else {
    $params = {}
  }
  class { 'puppet':
    runmode              => 'unmanaged',
    unavailable_runmodes => ['cron', 'systemd.timer'],
    usecacheonfailure    => false,
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
