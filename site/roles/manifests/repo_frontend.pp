# @summary Configures a system to be the public facing aspect of Vox Pupuli's repos
#
# Configures a system to be the public facing aspect of Vox Pupuli's repos.
# This includes the repositories maintained in support of the OpenVox project
# such as {artifacts,apt,downloads,rsync,yum}.voxpupuli.org. Different repos
# are presented in different ways. For example, the artifacts and downloads
# ones are simple directory listings while apt, rsync, and rsync are presented
# in an applications-specific way.
#
class roles::repo_frontend {
  include nftables::rules::http
  include nftables::rules::https
  include nftables::rules::rsync
}
