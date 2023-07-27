#
# @summary some resources to manage puppete code
#
# @author Tim Meusel <tim@bastelfreak.de>
#
class profiles::puppetcode {
  ssh_keygen { 'root_github':
    type     => 'ed25519',
    filename => '/root/.ssh/id_ed25519_github',
    home     => '/root',
    user     => 'root',
  }
  # /root/.ssh/config entry for the backup server
  ssh::client::config::user { 'root_github':
    ensure        => present,
    user          => 'root',
    user_home_dir => '/root',
    options       => {
      'Host github.com' => {
        'User'           => 'git',
        'IdentityFile'   => '~/.ssh/id_ed25519_github',
        'ControlMaster'  => 'auto',
        'ControlPath'    => '~/.ssh/ssh-%r@%h:%p',
        'ControlPersist' => 'yes',
      },
    },
  }
  if $facts['os']['name'] == 'Archlinux' {
    $deploy = { 'generate_types' => true, 'puppet_path' => '/usr/bin/puppet' }
    $version = 'installed'
  } else {
    $deploy = { 'generate_types' => true }
    # we hardcode this and update it from time to time.
    # agent runs faster compared to ensure latest
    $version = '3.16.0'
  }
  class { 'r10k':
    pool_size       => $facts['processors']['count']*2,
    sources         => {
      'puppet' => {
        'remote'  => 'git@github.com:voxpupuli/controlrepo.git',
        'basedir' => '/etc/puppetlabs/code/environments',
      },
    },
    version         => $version,
    deploy_settings => $deploy,
  }
  contain r10k
}
