#
# @api private
#
# @summary install ruby for GitHub self hosted runners
#
# @author Tim Meusel <tim@bastelfreak.de>
#
class profiles::github_runners::ruby (
  String[1] $user,
  String[1] $version,
  String[1] $group = $user,
  Stdlib::Absolutepath $home = '/',
  Hash $instances = {},
) {
  assert_private()

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

  ['2.7.8', '3.2.8', '3.3.8', '3.4.4'].each |$ruby| {
    # $ ruby-build 3.2.2 /scratch/actions/try/_work/_tool/Ruby/3.2.2/x64
    # Once that completes successfully, mark it as complete with:
    #  $ touch /scratch/actions/try/_work/_tool/Ruby/3.2.2/x64.complete

    $instances.each |$key, $data| {
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
}
