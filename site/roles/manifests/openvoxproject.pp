#
# @summary deploy our website
#
# @author Tim Meusel <tim@bastelfreak.de>
#
class roles::openvoxproject {
  include nftables::rules::http
  include nftables::rules::https
  include profiles::lets_encrypt
  include profiles::openvoxproject
}
