#
# @summary Configure key from a-st from GitHubs in the authorized_keys file along with supplemental keys
#
#
class profiles::ssh_keys::people::ast {
  profiles::update_ssh_authorized_keys(['a-st'])
}
