#
# @summary installs docker
#
# @author Tim Meusel <tim@bastelfreak.de>
#
class profiles::docker {
  class { 'docker':
    use_upstream_package_source => true,
    iptables                    => false,
  }
  contain docker
  include nftables::rules::docker_ce
}
