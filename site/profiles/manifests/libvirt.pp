#
# @summary installs libvirt
#
# @author Tim Meusel <tim@bastelfreak.de>
#
class profiles::libvirt {
  contain libvirt

  # works on Ubuntu 24.04
  package { ['genisoimage', 'libvirt-dev']:
    ensure => 'installed',
  }

  # https://github.com/jpartlow/nested_vms/blob/3ddfe3bb12ea5272809e115976df5e1448aeb5be/action.yaml#L141C70-L141C93
  libvirt_pool { 'default' :
    ensure    => present,
    type      => 'dir',
    autostart => true,
    target    => '/var/lib/libvirt/images',
  }

  include profiles::nftables
  include nftables::rules::qemu
  # https://fedoraproject.org/wiki/Changes/LibvirtVirtualNetworkNFTables#Upgrade/compatibility_impact
  $chains = ['LIBVIRT_FWI', 'LIBVIRT_FWO', 'LIBVIRT_FWX', 'LIBVIRT_INP', 'LIBVIRT_OUT']
  $chains.each |$chain| {
    nftables::chain { $chain: }
  }
}
