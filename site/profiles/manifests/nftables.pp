# @summary configure certain nftable rules
#
# @param in_ssh allows incoming ssh connections
# @param icmp allow all ICMP traffic
# @param nat decide if the box should be allowed to handle NAT traffic
# @param out_all Allow all outbound connections
#
class profiles::nftables (
  Boolean $in_ssh = true,
  Boolean $icmp = true,
  Boolean $nat = false,
  Boolean $out_all = false
) {
  class { 'nftables':
    in_ssh           => $in_ssh,
    in_icmp          => $icmp,
    out_icmp         => $icmp,
    in_out_conntrack => true,
    inet_filter      => true,
    nat              => $nat,
    reject_with      => false,
    out_all          => $out_all,
  }
  include nftables::rules::out::ssh
  include nftables::rules::out::whois
}
