#
# @summary configures all files in a home
#
# @param user the username
# @param group group name used for git operations
# @param basedir where the home should be created
# @param homedir absolute path to the actual home
# @param manage_dependencies if packages should be installed
#
define profiles::user_environment (
  String[1] $user = $title,
  String[1] $group = $user,
  Stdlib::Absolutepath $basedir = $user ? { 'root' => '/', default => '/home' },
  Stdlib::Absolutepath $homedir = "${basedir}/${user}",
  Stdlib::HTTPSUrl $gitrepo = 'https://github.com/bastelfreak/scripts',
  Array[String[1]] $dependencies = ['git', 'vim'],
  Boolean $manage_dependencies = false,
) {
  if $manage_dependencies {
    package { $dependencies:
      ensure => 'installed',
      before => [Vcsrepo["${homedir}/scripts"], Vcsrepo["${homedir}/.vim/bundle/Vundle.vim"],],
    }
  }
  vcsrepo { "${homedir}/scripts":
    ensure   => 'present',
    provider => 'git',
    revision => 'master',
    user     => $user,
    group    => $group,
    source   => $gitrepo,
  }
  file { "${homedir}/.bashrc":
    ensure  => 'link',
    target  => "${homedir}/scripts/bashrc",
    owner   => $user,
    group   => $group,
    require => Vcsrepo["${homedir}/scripts"],
  }
  file { "${homedir}/.bash_profile":
    ensure  => 'link',
    target  => "${homedir}/scripts/bash_profile",
    owner   => $user,
    group   => $group,
    require => Vcsrepo["${homedir}/scripts"],
  }
  file { "${homedir}/.vimrc":
    ensure  => 'link',
    target  => "${homedir}/scripts/vimrc",
    owner   => $user,
    group   => $group,
    require => Vcsrepo["${homedir}/scripts"],
  }
  file { "${homedir}/.vim":
    ensure => 'directory',
    owner  => $user,
    group  => $group,
  }
  file { "${homedir}/.vim/backupdir":
    ensure => 'directory',
    owner  => $user,
    group  => $group,
  }
  file { "${homedir}/.screenrc":
    ensure  => 'link',
    target  => "${homedir}/scripts/screenrc",
    owner   => $user,
    group   => $group,
    require => Vcsrepo["${homedir}/scripts"],
  }
  vcsrepo { "${homedir}/.vim/bundle/Vundle.vim":
    ensure   => 'present',
    provider => 'git',
    revision => 'master',
    user     => $user,
    group    => $group,
    source   => 'https://github.com/VundleVim/Vundle.vim.git',
  }
}
