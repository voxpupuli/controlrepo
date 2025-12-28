# @summary Configures an rsync server to present the files under /var/mirror
#
# Configures an rsync server to present the files under /var/mirror
#
# @api private
#
class profiles::download_server::rsync {
  assert_private()

  class { 'rsync':
    package_ensure => 'latest',
  }

  class { 'rsync::server':
    use_xinetd => false,
    uid        => 'nobody',
    gid        => 'nogroup',
    address    => '*',
  }

  rsync::server::module {
    default:
      path            => '/var/mirror',
      read_only       => 'yes',
      max_connections => '60',
      incoming_chmod  => false,
      outgoing_chmod  => false,
      uid             => 'nobody',
      gid             => 'nogroup',
    ;
    'all':
      comment => 'Vox Pupuli Artifacts, Downloads, and Repositories',
      exclude => ['/yum/lost+found/', '/apt/lost+found/'],
    ;
    'packages':
      comment => 'Vox Pupuli Downloads and Repositories',
      exclude => ['/artifacts/', '/yum/lost+found/', '/apt/lost+found/'],
    ;
  }
}
