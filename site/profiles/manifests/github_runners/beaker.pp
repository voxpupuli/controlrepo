#
# @summary configures beaker/libvirt/kvm
#
# @author Tim Meusel <tim@bastelfreak.de>
#
# @see https://github.com/jpartlow/nested_vms
# @see https://github.com/jpartlow/kvm_automation_tooling
#
class profiles::github_runners::beaker {
  # https://github.com/jpartlow/nested_vms/blob/3ddfe3bb12ea5272809e115976df5e1448aeb5be/action.yaml#L153
  ssh_keygen { 'ssh-id-test':
    type     => 'ed25519',
    user     => 'runner',
    filename => '/opt/runner/.ssh/ssh-id-test',
  }

  # https://github.com/jpartlow/nested_vms/blob/3ddfe3bb12ea5272809e115976df5e1448aeb5be/action.yaml#L117-L125
  require hashi_stack::repo
  package { 'terraform':
    ensure => 'installed',
  }
}
