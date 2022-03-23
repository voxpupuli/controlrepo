#
# @summary install latest postgresql with upstream repositories
#
# @param version desired postgresql version
#
# @author Tim Meusel <tim@bastelfreak.de>
#
class profiles::postgresql (
  Enum['11', '12', '13', '14'] $version = '13',
) {
  class { 'postgresql::globals':
    encoding            => 'UTF-8',
    locale              => 'en_US.UTF-8',
    version             => $version,
    manage_package_repo => true,
  }
  # don't contain it. causes apt cycles
  class { 'postgresql::server':
  }
  file { '/srv/pg_dumps':
    ensure => 'directory',
  }
  class { 'dbbackup':
    destination         => '/srv/pg_dumps',
    backuphistory       => 7,
    manage_dependencies => true,
    require             => File['/srv/pg_dumps'],
  }
  contain dbbackup
}