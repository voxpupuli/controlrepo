#
# @summary setup choria
#
# @param broker decide if this is just a server or also a broker
#
# @see https://choria.io/docs/
#
#  @author Tim Meusel <tim@bastelfreak.de>
#
class profiles::choria (
  Boolean $broker = false,
) {
  class { 'choria':
    manage_package_repo => true,
    log_level           => 'info',
    logfile             => 'stdout',
  }

  class { 'nftables::rules::out::choria':
    brokers => ['116.202.97.65', '2a01:4f8:c013:359b::1'],
  }

  if $broker {
    class { 'choria::broker':
      network_broker => true,
      websocket_port => 4333,
    }

    # https://choria.io/docs/deployment/broker/
    sysctl { 'net.core.somaxconn':
      ensure => 'present',
      value  => '4092',
    }
    sysctl { 'net.ipv4.tcp_max_syn_backlog':
      ensure => 'present',
      value  => '8192',
    }
    nftables::simplerule { 'allow_choria_4_in':
      action => 'accept',
      proto  => 'tcp',
      dport  => [4222, 4333,],
      saddr  => [
        '5.75.218.154/32',
        '95.216.183.49/32',
        '204.168.136.15/32',
        '138.199.224.35/32',
        '194.249.5.47/32',
        '157.90.132.251/32',
        '159.69.85.37/32',
        '95.217.246.117/32',
        '77.42.36.83/32',
        '62.238.5.87/32',
        "${facts['networking']['ip']}/32",
      ],
    }
    nftables::simplerule { 'allow_choria_6_in':
      action => 'accept',
      proto  => 'tcp',
      dport  => [4222, 4333,],
      saddr  => [
        '2a01:4f8:1c17:b00c::1/64',
        '2a01:4f9:c01f:802e::1/64',
        '2a01:4f9:c013:77c::1/64',
        '2a01:4f8:c013:b6cb::1/64',
        '2a01:4f8:252:4667::2/64',
        '2a01:4f8:c2c:7501::1/64',
        '2a01:4f9:c01f:9f8a::1/64',
        '2a01:4f9:c011:bcee::1/64',
        '2a01:4f9:c014:6bfb::1/64',
        "${facts['networking']['ip6']}/128",
      ],
    }

    user { 'mco':
      ensure         => 'present',
      system         => true,
      managehome     => true,
      purge_ssh_keys => true,
      shell          => '/usr/sbin/nologin',
    }
    group { 'mco':
      ensure => 'present',
      system => true,
    }
    exec { 'setup certificate':
      # choria prints the help if command is passed as array?!
      command     => 'choria enroll',
      user        => 'mco',
      group       => 'mco',
      cwd         => '/home/mco',
      path        => $facts['path'],
      provider    => 'shell',
      creates     => '/home/mco/.puppetlabs/etc/puppet/ssl/certs/mco.mcollective.pem',
      # one would assume that you have those environnment variable with provider=shell
      environment => ['USER=mco','HOME=/home/mco',],
    }
  }
}
