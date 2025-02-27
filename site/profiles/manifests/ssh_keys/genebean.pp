#
# @summary configure key from genebean from GitHubs in the authorized_keys file
#
# @param github_users list of github users, we will download their ssh keys
#
# @author Tim Meusel <tim@bastelfreak.de>
#
class profiles::ssh_keys::genebean (
  Array[String[1]] $github_users = ['genebean'],
) {
  profiles::update_ssh_authorized_keys($github_users)
}
