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
    saddr  => ['95.216.183.49/32', '204.168.136.15/32', '138.199.224.35/32', '194.249.5.47/32', '157.90.132.251/32', '159.69.85.37/32', '95.217.246.117/32', '77.42.36.83/32', "${facts['networking']['ip']}/32",],
  }
  nftables::simplerule { 'allow_puppet_6':
    action => 'accept',
    proto  => 'tcp',
    dport  => 8140,
    saddr  => ['2a01:4f9:c01f:802e::1/64', '2a01:4f9:c013:77c::1/64', '2a01:4f8:c013:b6cb::1/64', '2a01:4f8:252:4667::2/64', '2a01:4f8:c2c:7501::1/64', '2a01:4f9:c01f:9f8a::/64','2a01:4f9:c011:bcee::1', "${facts['networking']['ip6']}/128",],
  }
  nftables::simplerule { 'allow_openvoxdb_4':
    action => 'accept',
    proto  => 'tcp',
    dport  => 8081,
    saddr  => "${facts['networking']['ip']}/32",
  }
  nftables::simplerule { 'allow_openvoxdb_6':
    action => 'accept',
    proto  => 'tcp',
    dport  => 8081,
    saddr  => "${facts['networking']['ip6']}/128",
  }
  # allow connections from the agent/curl to reach the PuppetDB via http/https
  nftables::rule { 'default_out-openvoxdbv6':
    content => "tcp dport { 8080, 8081 } ip6 daddr ${facts['networking']['ip6']}/128 accept",
  }
  nftables::rule { 'default_out-openvoxdbv4':
    content => "tcp dport { 8080, 8081 } ip daddr ${facts['networking']['ip']}/32 accept",
  }

  # allow webhook access
  # https://api.github.com/meta
  nftables::simplerule { 'allow_webhook_4':
    action => 'accept',
    proto  => 'tcp',
    dport  => 4000,
    saddr  => ['192.30.252.0/22', '185.199.108.0/22', '140.82.112.0/20', '143.55.64.0/20',],
  }
  nftables::simplerule { 'allow_webhook_6':
    action => 'accept',
    proto  => 'tcp',
    dport  => 4000,
    saddr  => ['2a0a:a440::/29', '2606:50c0::/32'],
  }
}
