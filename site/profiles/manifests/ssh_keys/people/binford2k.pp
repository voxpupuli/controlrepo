#
# @summary Configure key from binford2k from GitHubs in the authorized_keys file
#
class profiles::ssh_keys::people::binford2k {
  profiles::update_ssh_authorized_keys(['binford2k'])
}
