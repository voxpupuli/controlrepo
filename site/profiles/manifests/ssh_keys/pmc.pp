#
# @summary configure keys from GitHubs in the authorized_keys file
#
# @param github_users list of github users, we will download their ssh keys
#
# @author Tim Meusel <tim@bastelfreak.de>
#
class profiles::ssh_keys::pmc (
  Array[String[1]] $github_users = ['bastelfreak', 'smortex', 'rwaffen', 'ekohl', 'sebastianrakel',],
) {
  profiles::update_ssh_authorized_keys($github_users)
}
