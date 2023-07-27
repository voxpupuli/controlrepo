#
# @summary configure keys from GitHubs in the authorized_keys file
#
# @param github_users list of github users, we will download their ssh keys
#
# @author Tim Meusel <tim@bastelfreak.de>
#
class profiles::ssh_keys (
  Array[String[1]] $github_users = ['bastelfreak', 'smortex', 'rwaffen', 'ekohl', 'sebastianrakel',],
) {
  $github_users.each |$user| {
    $keys = extlib::read_url("https://github.com/${user}.keys")
    $keys.split("\n").each |$index, $key| {
      $keyparts = $key.split(' ')
      ssh_authorized_key { "${user}-${index}":
        user => 'root',
        type => $keyparts[0],
        key  => $keyparts[1],
      }
    }
  }
}
