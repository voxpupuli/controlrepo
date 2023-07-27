# Puppet Code to manage [voxpupu.li](https://voxpupu.li)

[Hetzner cloud](https://www.hetzner.com/cloud) sponsors us a cloud instance.
It's currently running Ubuntu 18.04. This repository works as a control
repository for [r10k](https://github.com/puppetlabs/r10k#r10k).

The main purpose of this cloud instance is to run [Vox Pupuli Tasks](https://github.com/voxpupuli/vox-pupuli-tasks#vox-pupuli-tasks---the-webapp-for-community-management).

## Bootstrap

Assume we've got a new Ubuntu 18.04 cloud instance:

```sh
wget https://apt.puppet.com/puppet7-release-bionic.deb
dpkg -i puppet7-release-bionic.deb
apt update
apt --yes upgrade
apt --yes install puppet-agent
source /etc/profile.d/puppet-agent.sh
puppet module install puppet-r10k
puppet apply -e 'include r10k'
sed -i 's#remote:.*#remote: https://github.com/voxpupuli/controlpanel.git#' /etc/puppetlabs/r10k/r10k.yaml
r10k deploy environment production --puppetfile --verbose
puppet apply /etc/puppetlabs/code/environments/production/manifests/site.pp --show_diff
```

## Hetzner Cloud cloud-init userdata:

```yaml
#cloud-config
---
package_reboot_if_required: true
package_upgrade: true
packages:
- git
- ca-certificates
repo_update: true
repo_upgrade: all
puppet:
  install_type: aio
  collection: puppet8
  cleanup: false
  package_name: puppet-agent
runcmd:
  - /opt/puppetlabs/puppet/bin/gem install --no-document r10k
  - cd /root && git clone https://github.com/voxpupuli/controlrepo
  - cd /root/controlrepo && /opt/puppetlabs/puppet/bin/r10k puppetfile install
  - /opt/puppetlabs/puppet/bin/puppet apply /root/controlrepo/manifests/site.pp --modulepath /root/controlrepo/modules:/root/controlrepo/site --show_diff
```

## ToDos

* setup csr_attributes (cloud-inits supports that as well)
* write the r10k config so we can do the initial provisioning into `/etc/puppetlabs/code/environments` and not `/root`
