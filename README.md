# Puppet Code to manage [voxpupu.li](https://voxpupu.li)

[Hetzner cloud](https://www.hetzner.com/cloud) sponsors us a cloud instance.
It's currently running Ubuntu 18.04. This repository works as a control
repository for [r10k](https://github.com/puppetlabs/r10k#r10k).

The main purpose of this cloud instance is to run [Vox Pupuli Tasks](https://github.com/voxpupuli/vox-pupuli-tasks#vox-pupuli-tasks---the-webapp-for-community-management).

## Bootstrap

Assume we've got a new cloud instance:

```sh
wget https://apt.puppet.com/puppet6-release-bionic.deb
dpkg -i puppet6-release-bionic.deb
apt update
apt --yes upgrade
apt --yes install puppet-agent
source /etc/profile.d/puppet-agent.sh
puppet module install puppet-r10k
puppet apply -e 'include r10k'
sed -i 's#remote:.*#remote: https://github.com/voxpupuli/voxpupu.li.git#' /etc/puppetlabs/r10k/r10k.yaml
r10k deploy environment production --puppetfile --verbose
```
