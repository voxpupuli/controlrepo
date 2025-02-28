# @summary configure key from rwaffen from GitHubs in the authorized_keys file
#
class profiles::ssh_keys::people::rwaffen {
  profiles::update_ssh_authorized_keys(['rwaffen'])
}
