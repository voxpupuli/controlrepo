#
# @summary Configure key from smortex from GitHubs in the authorized_keys file along with supplemental keys
#
# Configure key from smortex from GitHubs in the authorized_keys file along with supplemental keys
#
class profiles::ssh_keys::people::smortex {
  profiles::update_ssh_authorized_keys(['smortex'])

  ssh_authorized_key { 'romain@fenchurch':
    ensure => 'present',
    user   => 'root',
    key    => 'AAAAC3NzaC1lZDI1NTE5AAAAILvGP9clA62A6cTrc68sqRp1m2MWVrpBy1EigRnMpSfG',
    type   => 'ssh-ed25519',
  }
}
