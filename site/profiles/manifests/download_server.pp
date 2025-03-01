# @summary Setup a server to present Vox Pupuli's files and packages for download over http and rsync
#
# Setup a server to present Vox Pupuli's files and packages for download over
# http and rsync. The files being served are sourced from OSL's S3-compatible
# bucket via rclone.
#
# @param server_names
#   A hash of Nginx server names to create. Each top-level key is a FQDN and
#   its value is made up of a location block and, optionally, a list of
#   aliases by which the server should also be known. The value of the
#   locations block is passed directly to a splat within an
#   `nginx::resource::location` resource.
#
class profiles::download_server (
  Hash[Stdlib::Fqdn, Struct[
      {
        locations => Hash,
        aliases   => Optional[Array[Stdlib::Fqdn]]
      }
    ]
  ] $server_names,
) {
  # This mainfest was getting unweildy so I broke it down into some subclasses
  # -- GeneBean 2025-03-03
  contain profiles::download_server::nginx
  contain profiles::download_server::rclone
  contain profiles::download_server::rsync
}
