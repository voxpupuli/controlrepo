#
# @summary creates a new user for openvoxproject staging website
#
# @author Tim Meusel <tim@bastelfreak.de>
#
class profiles::openvoxproject_user {
  quadlets::user { 'openvox-staging':
    subuid => [100000, 65536],
    subgid => [100000, 65536],
  }
  quadlets::user { 'openvox-prod':
    subuid => [200000, 65536],
    subgid => [200000, 65536],
  }
  quadlets::quadlet { 'staging-openvoxproject-org.container':
   ensure          => 'present',
   user            => 'openvox-staging',
   location        => 'system',
   active          => true,
   unit_entry      => {
     'Description' => 'run our container',
   },
   container_entry => {
     'Image'       => 'ghcr.io/avitacco/openvoxproject:latest',
     'AutoUpdate'  => 'registry',
     'PublishPort' => '8080:8080', #HostPort:ContainerPort
   },
   install_entry   => {
     'WantedBy' => 'default.target',
   },
   require         => Quadlets::User['openvox-staging'],
 }
 # podman shall fetch new images
 service { 'podman-auto-update.timer':
   ensure => 'running',
   enable => true,
 }
}
