#
# @summary manages nft rules on Puppetserver/PuppetDB
#
# @author Tim Meusel <tim@bastelfreak.de>
#
# @api private
class profiles::puppet::server_firewalling {
  assert_private()
  include profiles::nftables
  nftables::simplerule { 'allow_puppet_4':
    action => 'accept',
    proto  => 'tcp',
    dport  => 8140,
    saddr  => ['194.249.5.47/32', '157.90.132.251/32', '159.69.85.37/32', '95.217.246.117/32', '77.42.36.83/32', "${facts['networking']['ip']}/32",],
  }
  nftables::simplerule { 'allow_puppet_6':
    action => 'accept',
    proto  => 'tcp',
    dport  => 8140,
    saddr  => ['2a01:4f8:252:4667::2/64', '2a01:4f8:c2c:7501::1/64', '2a01:4f9:c01f:9f8a::/64','2a01:4f9:c011:bcee::1', "${facts['networking']['ip6']}/128",],
  }
  nftables::simplerule { 'allow_puppetdb_4':
    action => 'accept',
    proto  => 'tcp',
    dport  => 8081,
    saddr  => "${facts['networking']['ip']}/32",
  }
  nftables::simplerule { 'allow_puppetdb_6':
    action => 'accept',
    proto  => 'tcp',
    dport  => 8081,
    saddr  => "${facts['networking']['ip6']}/128",
  }
  # allow connections from the agent/curl to reach the PuppetDB via http/https
  nftables::rule { 'default_out-puppetdbv6':
    content => "tcp dport { 8080, 8081 } ip6 daddr ${facts['networking']['ip6']}/128 accept",
  }
  nftables::rule { 'default_out-puppetdbv4':
    content => "tcp dport { 8080, 8081 } ip daddr ${facts['networking']['ip']}/32 accept",
  }
}
