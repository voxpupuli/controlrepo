#
# @summary multiple profiles requires nginx vhosts, this profile pulls in the nginx class/package/service setup
#
# @author Tim Meusel <tim@bastelfreak.de>
#
class profiles::nginx {
  # do not contain it because it triggers also apt, which is triggerd by other profiles as well
  include nginx
}
