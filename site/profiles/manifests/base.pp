#
# @summary ssh profile to manage basic stuff that doesn't fit into a dedicated profile
#
# @param manage_borg whether borg should be installed or not
#
# @author Tim Meusel <tim@bastelfreak.de>
#
class profiles::base (
  Boolean $manage_borg = true,
) {
  package { ['make', 'gcc', 'build-essential', 'htop', 'lsb-release', 'ctop', 'ca-certificates', 'apt-file']:
    ensure => 'installed',
  }
  exec { 'refresh apt-file cache':
    refreshonly => true,
    command     => '/usr/bin/apt-file update',
    subscribe   => Package['apt-file'],
  }
  package { 'snapd':
    ensure => 'absent',
  }
  # https://www.sshaudit.com/hardening_guides.html
  class { 'ssh':
    storeconfigs_enabled => false,
    validate_sshd_file   => true,
    server_options       => {
      'PasswordAuthentication' => 'no',
      'PermitRootLogin'        => 'without-password',
      'X11Forwarding'          => 'no',
      'PrintMotd'              => 'yes',
      'AllowAgentForwarding'   => 'no',
      'Protocol'               => 2,
      'Port'                   => 22,
    },
    client_options       => {
      'Host *' => {
        'Ciphers'           => 'chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr',
        'KexAlgorithms'     => 'curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256',
        'MACs'              => 'hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com',
        'HostKeyAlgorithms' => 'ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,sk-ssh-ed25519-cert-v01@openssh.com,rsa-sha2-256,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-512-cert-v01@openssh.com',
      },
    },
  }
  contain ssh
  if $manage_borg {
    contain profiles::borg
  }
}
