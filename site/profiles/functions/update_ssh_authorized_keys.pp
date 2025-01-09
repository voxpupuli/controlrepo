#
# @summary generate ssh_authorized_key root entries for a list of github users
#
# @param github_users the list of users
#
# @author Tim Meusel <tim@bastelfreak.de>
#
function profiles::update_ssh_authorized_keys(Array[String[1]] $github_users) {
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
