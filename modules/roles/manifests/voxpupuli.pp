class roles::voxpupuli {
  contain profiles::basics
  contain profiles::puppetagent
  Class['profiles::basics']
  -> Class['profiles::puppetagent']
}
