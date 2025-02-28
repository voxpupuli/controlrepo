# @summary Allow additional admins' keys to be pulled in via Hiera
#
# Allow additional admins' keys to be pulled in via Hiera
#
# @param user_list [Array[String[1]]]
#   The list of users whose ssh keys should be pulled in. Each listed user will
#   need to be represented by a manifest under `site/profiles/manifests/ssh_keys/people`.
#
class profiles::ssh_keys::additional_keys (
  Array[String[1]] $user_list = [],
) {
  $user_list.each |$user| {
    include "profiles::ssh_keys::people::${user}"
  }
}
