#
# @summary Configure key from sebastianrakel from GitHubs in the authorized_keys file along with supplemental keys
#
# Configure key from sebastianrakel from GitHubs in the authorized_keys file along with supplemental keys
#
class profiles::ssh_keys::people::sebastianrakel {
  profiles::update_ssh_authorized_keys(['sebastianrakel'])

  ssh_authorized_key {
    default:
      ensure => 'present',
      user   => 'root',
      type   => 'ssh-rsa',
      ;
    'Spritzgebaeck-ed25519':
      key  => 'AAAAC3NzaC1lZDI1NTE5AAAAINo6u1C58Gc4ZzpgxsDSPK49i+bnvPZv/p5Tyw2/NwyP',
      type => 'ssh-ed25519',
      ;
    'spritzgebaeck-rsa':
      key  => 'AAAAB3NzaC1yc2EAAAADAQABAAABgQDS2uZyrP/EFeakDm9/GRRj/K3CknCwd8Z30Yj/zP0HTfvQyjCSMLCkavX6P8rhMy8UggsWkgWWGT8OAZmSfWChmlmtSypGR2W9/HYdWTqE/XbJxgplwExo7/s9qjZ5XQd4Htyt75egU0ZX7Ag1p2jvY3G+UMOHgHxrddtJgufIEaUYJRd76wpseP6hC2BojR0FR3WtOnYyG78PUzNF/7FYCRLSsSN7TS7dwObZjsxRcwv+jurGag8tbgcGqaF8XgtngLje5AFmaL1G7uuGJYWFjCAk3Ha1sjaqivyDvvirouU0Ma/ZlxTVx31wQTqa7FO24+FaEBerO9gxlSplRNSo7CB7WQTAdGGJOAEqDoug2H14DUPGiACO6sQ5vAqMUc9NLxyWucKVeCEW2T50brHrAsXZUWioSU26y8MANwV5Oy5lrxl48igXlxq6uDSkGf/jiNAHW59emnHfiMSjN9nrXfeYmuGX1YFe9CvWakSIXxqFh1/l3ySc1KxQwzR8Lyk=',
      type => 'ssh-rsa',
      ;
  }
}
