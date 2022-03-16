#
# @summary some resources to manage puppete code
#
# @author Tim Meusel <tim@bastelfreak.de>
#
class profiles::puppetcode {
  if $facts['os']['name'] == 'Archlinux' {
    $deploy = { 'generate_types' => true, 'puppet_path' => '/usr/bin/puppet' }
    $version = 'installed'
  } else {
    $deploy = { 'generate_types' => true }
    # we hardcode this and update it from time to time.
    # agent runs faster compared to ensure latest
    $version = '3.14.2'
  }
  class { 'r10k':
    pool_size       => $facts['processors']['count']*2,
    sources         => {
      'puppet' => {
        'remote'  => 'git@github.com:voxpupuli/controlrepo.git',
        'basedir' => '/etc/puppetlabs/code/environments',
      },
    },
    version         => $version,
    deploy_settings => $deploy,
  }
}
