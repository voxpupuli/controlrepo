#
# @summary manages nft rules on Puppetserver/PuppetDB
#
# @author Tim Meusel <tim@bastelfreak.de>
#
class profiles::puppetserver_firewalling {
  include profiles::nftables
  nftables::simplerule { 'allow_puppet_4':
    action => 'accept',
    proto  => 'tcp',
    dport  => 8140,
    saddr  => "${facts['networking']['ip']}/32",
  }
  nftables::simplerule { 'allow_puppet_6':
    action => 'accept',
    proto  => 'tcp',
    dport  => 8140,
    saddr  => "${facts['networking']['ip6']}/128",
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
