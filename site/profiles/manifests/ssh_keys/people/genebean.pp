# @summary configure key from genebean from GitHubs in the authorized_keys file
#
class profiles::ssh_keys::people::genebean {
  profiles::update_ssh_authorized_keys(['genebean'])
}
