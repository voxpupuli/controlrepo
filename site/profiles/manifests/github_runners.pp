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
  Array[String[1]] $instances = ['first','second','third','fourth','fifth','sixth','senventh', 'eighth', 'ninth', 'tenth', 'eleventh', 'twelfth', 'thirteenth', 'fourteenth', 'fifteenth', 'sixteenth'],
) {
  package { ['jq', 'libffi-dev', 'libyaml-dev', 'libreadline-dev', 'zlib1g-dev', 'libssl-dev',]:
    ensure => 'installed',
  }
  $home = "/opt/${user}"
  user { $user:
    ensure         => 'present',
    managehome     => true,
    purge_ssh_keys => true,
    system         => true,
    home           => $home,
    forcelocal     => true,
    shell          => '/usr/sbin/nologin',
    groups         => $groups,
    # Notify the class to reload the runner
    # require when the docker integration is added later on
    notify         => Class['github_actions_runner'],
  }
  group { $group:
    ensure     => 'present',
    system     => true,
    forcelocal => true,
  }

  # workaround for the too old ruby-build package in Debian bookworm...
  # afterwards we need to run PREFIX=~/.local/ ./install.sh
  vcsrepo { "${home}/.rbenv/plugins/ruby-build":
    ensure   => 'present',
    provider => 'git',
    source   => 'https://github.com/rbenv/ruby-build.git',
    user     => $user,
    notify   => Exec['install-ruby-build'],
  }
  exec { 'install-ruby-build':
    command     => ["${home}/.rbenv/plugins/ruby-build/install.sh"],
    refreshonly => true,
    user        => $user,
    cwd         => "${home}/.rbenv/plugins/ruby-build",
    path        => $facts['path'],
    environment => ["PREFIX=${home}/.local/"],
    provider    => 'shell',
  }

  $_instances = $instances.map | $inst | {
    {
      $inst => {
        'labels'     => ['self-hosted', 'macarne',],
        'repo_name'  => $repo_name,
        'repo_token' => lookup("runner_${$inst}_${repo_name}", Optional[String[1]], 'first', undef),
        runner_group => 'Macarne-runners',
      }.delete_undef_values
    }
  }.reduce | $_memo, $_kv | { $_memo + $_kv }

  class { 'github_actions_runner':
    ensure         => present,
    package_ensure => $version,
    base_dir_name  => "${home}/actions-runner",
    package_name   => 'actions-runner-linux-x64',
    repository_url => 'https://github.com/actions/runner/releases/download',
    #personal_access_token => Deferred('teigi::get',['pat']),
    org_name       => 'voxpupuli',
    user           => $user,
    group          => $group,
    instances      => $_instances,
  }
  contain github_actions_runner

  ['2.7.8', '3.2.5', '3.3.4'].each |$ruby| {
    # $ ruby-build 3.2.2 /scratch/actions/try/_work/_tool/Ruby/3.2.2/x64
    # Once that completes successfully, mark it as complete with:
    #  $ touch /scratch/actions/try/_work/_tool/Ruby/3.2.2/x64.complete

    $_instances.each |$key, $data| {
      $_work = "${home}/actions-runner-${version}/${key}/_work"
      $_dest = "${_work}/_tool/Ruby/${ruby}/x64"
      exec { "ruby_build_${ruby}_${key}":
        user     => $user,
        group    => $group,
        cwd      => $home,
        command  => "ruby-build ${ruby} ${_dest} && /usr/bin/touch ${_dest}.complete",
        creates  => "${_dest}.complete",
        timeout  => 600, # 10 minutes
        require  => Exec['install-ruby-build'],
        path     => "${home}/.local/bin/:${facts['path']}",
        provider => 'shell',
      }
    }
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
