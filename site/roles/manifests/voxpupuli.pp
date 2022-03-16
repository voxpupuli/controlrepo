#
# @summary ssh role that contains all of our profiles
#
# @author Tim Meusel <tim@bastelfreak.de>
#
class roles::voxpupuli {
  contain profiles::basics
  contain profiles::ssh
  contain profiles::puppetagent
  Class['profiles::basics']
  -> Class['profiles::puppetagent']
}
