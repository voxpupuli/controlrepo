#
# @summary ssh profile to manage sshd + ssh keys
#
# @author Tim Meusel <tim@bastelfreak.de>
#
class profiles::ssh {
  contain ssh

  # /root/.ssh/config entry to access github.com fast
  ssh::client::config::user { 'root_github':
    ensure        => present,
    user          => 'root',
    user_home_dir => '/root',
    options       => {
      'Host github.secureserver.net' => {
        'User'           => 'git',
        'IdentityFile'   => '~/.ssh/id_ed25519_github',
        'ControlMaster'  => 'auto',
        'ControlPath'    => '~/.ssh/ssh-%r@%h:%p',
        'ControlPersist' => '10m',
      },
    },
  }
  # setup ssh key exchange
  ssh_keygen { 'root_github':
    type     => 'ed25519',
    user     => 'root',
    filename => "/root/.ssh/id_ed25519_github",
  }
}
