#
# @summary configures borg backups
#
# @param borg_excludes paths you do not want to backup
# @param borg_includes additional dirs you want to backup
# @param borg_compression the desired compression algo for borg
# @param borg_keep_yearly how many years to backup
# @param borg_keep_monthly how many months to backup
# @param borg_keep_weekly how many weeks to backup
# @param borg_keep_daily how many days to backup
# @param borg_keep_within how many days to keep all created backups
# @param absolutebackupdestdir the subdir on the backupserver where borg places backups
#
# @author Tim Meusel <tim@bastelfreak.de>
#
class profiles::borg (
  Array[Stdlib::Absolutepath] $borg_excludes = [],
  Array[Stdlib::Absolutepath] $borg_includes = [],
  String[1] $borg_compression = 'auto,zstd,6',
  Integer[0] $borg_keep_yearly = 3,
  Integer[0] $borg_keep_monthly = 6,
  Integer[0] $borg_keep_weekly = 4,
  Integer[0] $borg_keep_daily = 14,
  Integer[0] $borg_keep_within = 14,
  String[1] $absolutebackupdestdir = $facts['networking']['hostname'],
) {
  # setup borg. Requires powertools and epel repo on RedHat os family
  if $facts['os']['family'] == 'RedHat' {
    $borg_require = [Yumrepo['powertools'],Package['epel-release']]
  } else {
    $borg_require = undef
  }
  class { 'borg':
    create_prometheus_metrics              => false,
    update_borg_restore_db_after_backuprun => false,
    install_restore_script                 => false,
    backupserver                           => 'u263171.your-storagebox.de',
    username                               => 'u263171',
    ssh_port                               => 23,
    absolutebackupdestdir                  => $absolutebackupdestdir,
    additional_excludes                    => $borg_excludes,
    additional_includes                    => $borg_includes,
    keep_yearly                            => $borg_keep_yearly,
    keep_monthly                           => $borg_keep_monthly,
    keep_weekly                            => $borg_keep_weekly,
    keep_daily                             => $borg_keep_daily,
    keep_within                            => $borg_keep_within,
    compression                            => $borg_compression,
    additional_exclude_pattern             => ['sh:/opt/puppetlabs/puppet/cache/r10k/*'],
    require                                => $borg_require,
  }
}
