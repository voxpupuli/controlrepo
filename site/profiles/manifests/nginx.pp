#
# @summary multiple profiles requires nginx vhosts, this profile pulls in the nginx class/package/service setup
#
# @author Tim Meusel <tim@bastelfreak.de>
#
class profiles::nginx {
  # do not contain it because it triggers also apt, which is triggerd by other profiles as well
  require profiles::certbot
  $manage_repo = $facts['os']['name'] ? {
    'Archlinux' => false,
    default     => true,
  }
  class { 'nginx':
    confd_purge               => true,
    service_config_check      => true,
    ssl_protocols             => 'TLSv1.2 TLSv1.3',
    ssl_prefer_server_ciphers => 'on',
    worker_processes          => 'auto',
    ssl_ciphers               => 'ECDHE+AESGCM:DHE+AESGCM:ECDHE+ECDSA+AES+SHA256',
    manage_repo               => $manage_repo,
  }
}
