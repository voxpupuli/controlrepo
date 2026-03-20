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
  include profiles::ssh_keys::additional_keys
  include profiles::ssh_keys::pmc
  include profiles::choria

  if $manage_borg {
    contain profiles::borg
  }

  $_base_packages = [
    "linux-generic-hwe-${facts['os']['release']['major']}",
    'apt-file',
    'build-essential',
    'ca-certificates',
    'ccze',
    'dfc',
    'file',
    'gcc',
    'htop',
    'lsb-release',
    'make',
    'ncdu',
    'tree',
    'unzip',
    'uptimed',
    'whois',
    'jq',
  ]

  package { $_base_packages:
    ensure => 'installed',
  }

  package { ['snapd', 'ubuntu-pro-client-l10n', 'ubuntu-pro-client']:
    ensure => 'absent',
  }

  # disable services that talk to Canonical
  service { ['update-notifier-motd.timer', 'apt-news.service',  'esm-cache.service']:
    ensure => 'stopped',
    enable => 'mask',
  }

  # remove apt hook that talks to canonical
  file { '/etc/apt/apt.conf.d/20apt-esm-hook.conf':
    ensure => 'absent',
  }

  exec { 'refresh apt-file cache':
    refreshonly => true,
    command     => '/usr/bin/apt-file update',
    subscribe   => Package['apt-file'],
  }

  service { 'uptimed':
    ensure  => 'running',
    enable  => true,
    require => Package['uptimed'],
  }

  # do an apt update daily, don't log it, run it before packages
  class { 'apt':
    update => {
      frequency => 'daily',
      loglevel  => 'debug',
    },
  }
  # ensure update runs before installing packages
  Class['apt::update'] -> Package <| provider == 'apt' |>

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
      'MaxStartups'            => '100:10:300',
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

  # add vox-pupuli-tasks admin keys
  ssh_authorized_key {
    default:
      ensure => 'present',
      user   => 'root',
      type   => 'ssh-ed25519',
    ;
    'robert@Roberts-MBP.fritz.box':
      key => 'AAAAC3NzaC1lZDI1NTE5AAAAIKpAtp1I07CyFhixqy97toXzv2cuhRJZj22YorhhH7Ds',
    ;
    'robert@pc-mueller-2016-07-15':
      key => 'AAAAC3NzaC1lZDI1NTE5AAAAIGEVvWqFedfEkG63cWq5iwdkptC/lXr/jWjpqW0EktU3',
    ;
    'robert@DESKTOP-EV17QP6':
      key => 'AAAAC3NzaC1lZDI1NTE5AAAAIHwJ9FqCygbcCLNNqKlyN9nflIcHrxfxWmgEz08+EEUY',
    ;
  }

  # manage root so we can purge unknown keys
  user { 'root':
    ensure         => 'present',
    purge_ssh_keys => true,
  }

  # install sensors if we are on a physical system
  if $facts['virtual'] == 'physical' {
    package { 'lm-sensors':
      ensure => 'installed',
    }
  }

  # install nvme tools if we have an nvme
  if $facts['disks'].keys.any |$disk| { $disk =~ /nvme/ } {
    package { 'nvme-cli':
      ensure => 'installed',
    }
  }

  include profiles::nftables

  # colourize the shell
  file { '/etc/profile.d/shell_setup.sh':
    ensure  => 'file',
    content => file("${module_name}/shell_setup.sh"),
  }

  # configure puppet agent/server
  contain profiles::puppet

  # ensure we've the correct FQDN set
  if $trusted['certname'] {
    file { '/etc/hostname':
      content => "${trusted['certname']}\n",
    }
  }

  # adds the foreman smartproxy ssh key to all nodes for openbolt
  include 'foreman_proxy::plugin::remote_execution::ssh_user'
}
