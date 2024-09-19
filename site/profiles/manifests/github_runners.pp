#
# @summary configures a self-hosted github runner
#
# @param labels the labels that we will assign
# @param user the user that runs the runner
# @param group the group that runs the runner
# @param version version of the runner, matches their upstream github release names
# @param instances amount (and names) for all runners we create within one group
# @param repo_name set it to configure an repo-specific and not org specific runner
# @param setup_ruby installs ruby for rspec-puppet unit tests
# @param setup_docker installs docker for beaker jobs
# @param setup_libvirt installs libvirt and adds the user to the group
# @param runner_group the group that we will assign to the runners. Needs to exist
#
# @see code provided by CERN
#
# @author Tim Meusel <tim@bastelfreak.de>
#
class profiles::github_runners (
  Array[String[1]] $labels = ['self-hosted',],
  String[1] $user = 'runner',
  String[1] $group = $user,
  String[1] $version = '2.319.1',
  Optional[String[1]] $repo_name = undef,
  Array[String[1]] $instances = [],
  Boolean $setup_ruby = false,
  Boolean $setup_docker = false,
  Boolean $setup_libvirt = false,
  Optional[String[1]] $runner_group = undef,
) {
  package { ['jq', 'libffi-dev', 'libyaml-dev', 'libreadline-dev', 'zlib1g-dev', 'libssl-dev',]:
    ensure => 'installed',
  }
  $home = "/opt/${user}"
  $groups_d = if $setup_docker {
    ['docker']
  } else {
    []
  }
  $groups_l = if $setup_libvirt {
    ['libvirt']
  } else {
    []
  }

  user { $user:
    ensure         => 'present',
    managehome     => true,
    purge_ssh_keys => true,
    system         => true,
    home           => $home,
    forcelocal     => true,
    shell          => '/usr/sbin/nologin',
    groups         => $groups_d + $groups_l,
    # Notify the class to reload the runner
    # require when the docker integration is added later on
    notify         => Class['github_actions_runner'],
  }
  group { $group:
    ensure     => 'present',
    system     => true,
    forcelocal => true,
  }

  $_instances = $instances.map | $inst | {
    {
      $inst => {
        'labels'       => $labels,
        'repo_name'    => $repo_name,
        'repo_token'   => lookup("runner_${$inst}_${repo_name}", Optional[String[1]], 'first', undef),
        'runner_group' => $runner_group,
      }.delete_undef_values
    }
  }.reduce | $_memo, $_kv | { $_memo + $_kv }

  class { 'github_actions_runner':
    ensure         => present,
    package_ensure => $version,
    base_dir_name  => "${home}/actions-runner",
    repository_url => 'https://github.com/actions/runner/releases/download',
    #personal_access_token => Deferred('teigi::get',['pat']),
    org_name       => 'voxpupuli',
    user           => $user,
    group          => $group,
    instances      => $_instances,
  }
  contain github_actions_runner

  if $setup_ruby {
    class { 'profiles::github_runners::ruby':
      home      => $home,
      instances => $_instances,
      user      => $user,
      version   => $version,
    }
  }

  if $setup_docker {
    # setup a docker daemon
    require profiles::docker
  }

  if $setup_libvirt {
    require profiles::libvirt
  }

  # some github actions want to configure repos
  # ideally we update gha-puppet and our self hosted runners already have the packages installed
  include sudo
  sudo::conf { 'runner-ppa':
    priority => 10,
    content  => 'runner ALL=(ALL) NOPASSWD: /usr/bin/add-apt-repository',
  }
  sudo::conf { 'runner-aptupdate':
    priority => 10,
    content  => 'runner ALL=(ALL) NOPASSWD: /usr/bin/apt-get update',
  }
  sudo::conf { 'runner-aptinstall':
    priority => 10,
    content  => 'runner ALL=(ALL) NOPASSWD: /usr/bin/apt-get install -y *',
  }
}
