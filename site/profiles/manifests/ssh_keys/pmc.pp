# @summary Configure keys from GitHub of PMC members in the authorized_keys file
#
# Configure keys from GitHub of PMC members in the authorized_keys file.
# The PMC's member list is maintained in global.yaml and looked up directly.
#
class profiles::ssh_keys::pmc {
  $_pmc_members = lookup('pmc_members')
  $_pmc_members.each |$member| {
    include "profiles::ssh_keys::people::${member}"
  }
}
