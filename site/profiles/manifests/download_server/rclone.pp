# @summary Configures a server with rclone and mirrors data from OSL's S3-compatible buckets
#
# Configures a server with rclone and mirrors data from OSL's S3-compatible buckets
#
# @api private
#
class profiles::download_server::rclone {
  assert_private()

  include rclone

  # unzip is pulled in by profiles::base but we need to make sure it gets installed first:
  Package <| title == 'unzip' |> {
    before => Class['rclone::install'],
  }

  $_rclone_config = @("EOF")
    [OpenVox]
    type = s3
    provider = Other
    env_auth = false
    endpoint = https://s3.osuosl.org
    | EOF

  file {
    default:
      ensure  => directory,
      owner   => 'www-data',
      group   => 'www-data',
      require => Class['nginx'],
      ;
    '/var/mirror': ;
    '/var/www': ;
    '/var/www/.rclone.conf':
      ensure  => file,
      content => $_rclone_config,
      ;
  }

  file {
    default:
      ensure  => directory,
      owner   => 'www-data',
      group   => 'www-data',
      require => File['/var/mirror'],
      ;
    '/var/mirror/downloads': ;
    '/var/mirror/apt': ;
    '/var/mirror/yum': ;
    '/var/mirror/artifacts': ;
  }

  mount { '/var/mirror/downloads':
    ensure  => mounted,
    atboot  => true,
    device  => '/var/mirror/artifacts/downloads',
    fstype  => 'none',
    options => 'bind',
    require => File['/var/mirror/downloads'],
  }

  cron::hourly {
    default:
      user        => 'www-data',
      environment => ['MAILTO=root', 'PATH="/usr/bin:/bin"',],
      require     => [
        Class['rclone::install'],
        File[
          '/var/mirror',
          '/var/www/.rclone.conf',
        ],
      ],
      ;
    'sync-apt-from-OSL':
      minute  => '20',
      command => 'rclone sync --exclude index.html OpenVox:openvox-apt /var/mirror/apt',
      ;
    'sync-artifacts-from-OSL':
      minute  => '25',
      command => 'rclone sync --exclude index.html OpenVox:openvox-artifacts /var/mirror/artifacts',
      ;
    'sync-yum-from-OSL':
      minute  => '30',
      command => 'rclone sync --exclude index.html OpenVox:openvox-yum /var/mirror/yum',
      ;
  }
}
