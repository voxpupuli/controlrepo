#
# @summary Configure key from ananace from GitHubs in the authorized_keys file along with supplemental keys
#
class profiles::ssh_keys::people::bastelfreak {
  profiles::update_ssh_authorized_keys(['ananace'])
}
