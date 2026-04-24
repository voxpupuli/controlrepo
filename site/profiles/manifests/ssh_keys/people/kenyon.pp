# @summary configure key from nmburgan from GitHubs in the authorized_keys file
#
#
class profiles::ssh_keys::people::nmburgan {
  profiles::update_ssh_authorized_keys(['kenyon'])
}
