#
# @summary installs grafana to display stats from dropsonde about Vox Pupuli modules
#
# @see https://dev.to/puppet/help-us-understand-how-you-use-open-source-puppet-51aj
#
# @author Tim Meusel <tim@bastelfreak.de>
#
class profiles::grafana {
  require profiles::nginx
  require profiles::certbot
  package { 'toml':
    ensure   => 'installed',
    provider => 'puppet_gem',
  }
  class { 'grafana':
    install_method => 'repo',
    cfg            => {
      server => {
        http_addr => '127.0.0.1',
        http_port => 3001,
      },
    },
    require        => Package['toml'],
  }
  contain grafana
}
