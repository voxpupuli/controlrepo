# Vox Pupuli infrastructure control repository

Puppet code for the Vox Pupuli fleet: an [r10k](https://github.com/puppetlabs/r10k#r10k)
control repository holding the roles, profiles, and hiera data for every
`voxpupu.li` host. Servers are sponsored by
[Hetzner cloud](https://www.hetzner.com/cloud) and run Ubuntu 22.04/24.04
with [OpenVox](https://voxpupuli.org/openvox/) 8 agents.

## What it manages

| Node | Role | Runs |
| ---- | ---- | ---- |
| `puppetserver.voxpupu.li` | via `pp_role` | OpenVox server, Foreman, PuppetDB, Choria broker |
| `voxpupu.li` | `roles::voxpupuli` | [Vox Pupuli Tasks](https://github.com/voxpupuli/vox-pupuli-tasks#vox-pupuli-tasks---the-webapp-for-community-management), Grafana, Prometheus, [puppetmodule.info](https://www.puppetmodule.info), Postfix |
| `mirror.voxpupu.li` | `roles::download_server` | apt/yum artifact mirror |
| `ci01`/`ci02.voxpupu.li` | `roles::github_runner` | GitHub Actions runners |
| `matrix01.voxpupu.li` | `roles::matrix_server` | Matrix Synapse (in progress, #202) |

Other `data/nodes/*.yaml` files carry per-node data for hosts without a
dedicated role class.

## How classification works

`manifests/site.pp` gives every node `profiles::base`, then includes the
single role named by a hiera `role` key plus any extra classes from a
`classes` array. The hiera hierarchy (`hiera.yaml`, eyaml-encrypted
secrets) resolves in this order:

1. `data/nodes/%{facts.networking.fqdn}.yaml`
2. `data/roles/%{trusted.extensions.pp_role}.yaml` (the `pp_role` CSR
   extension set at provisioning time)
3. `data/global.yaml`

Roles live in `site/roles`, profiles in `site/profiles`. Module versions
are pinned in the `Puppetfile`.

## Node lifecycle

New nodes bootstrap masterless: cloud-init installs the agent, clones this
repo, and runs `puppet apply` against `manifests/site.pp` (the pluginsync
`file` hack at the top of site.pp exists for exactly this). After the
first apply the node runs `puppet agent` against the puppetserver, which
deploys this repo with r10k; reports land in Foreman and PuppetDB.

Example first apply on a fresh Ubuntu 24.04 host:

```sh
wget https://apt.voxpupuli.org/openvox8-release-ubuntu24.04.deb
dpkg -i openvox8-release-ubuntu24.04.deb
apt update
apt --yes install openvox-agent git
/opt/puppetlabs/puppet/bin/gem install --no-document r10k
git clone https://github.com/voxpupuli/controlrepo /root/controlrepo
cd /root/controlrepo
/opt/puppetlabs/puppet/bin/r10k puppetfile install --verbose
/opt/puppetlabs/bin/puppet apply manifests/site.pp \
  --modulepath modules:site --hiera_config hiera.yaml --show_diff
```

The historical Hetzner cloud-init userdata (predates the OpenVox switch,
kept as a reference for the csr_attributes/pp_role wiring):

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
  csr_attributes:
    extension_requests:
      pp_role: puppetserver
runcmd:
  - systemctl disable --now puppet
  - /opt/puppetlabs/puppet/bin/gem install --no-document r10k toml
  - cd /root && git clone https://github.com/voxpupuli/controlrepo
  - cd /root/controlrepo && /opt/puppetlabs/puppet/bin/r10k puppetfile install --verbose
  - /opt/puppetlabs/puppet/bin/puppet apply /root/controlrepo/manifests/site.pp --modulepath /root/controlrepo/modules:/root/controlrepo/site --show_diff --write_catalog_summary --hiera_config /root/controlrepo/hiera.yaml --summarize --graph --tags r10k,hacked_pluginsync
  - /opt/puppetlabs/puppet/bin/r10k deploy environment --modules --verbose
  - /opt/puppetlabs/puppet/bin/puppet apply /etc/puppetlabs/code/environments/production/manifests/site.pp --show_diff --environment production --write_catalog_summary --summarize --graph
  - /opt/puppetlabs/puppet/bin/puppet agent -t
  - /opt/puppetlabs/puppet/bin/puppet agent -t
```

## Making changes

CI runs on every pull request: yamllint over the hiera data, Puppetfile
validation, lint/rubocop, and the rspec-puppet suite in
`site/profiles/spec` (which compiles catalogs against the real hiera
data, so type errors and duplicate resources surface before merge).

```sh
cd site/profiles
bundle install
bundle exec rake validate lint check rubocop
bundle exec rake parallel_spec
```

When a change is risky enough to deserve a real machine,
[controlrepo-lab](https://github.com/miharp/controlrepo-lab) applies this
repo masterless on fresh Ubuntu 24.04 Vagrant VMs, one machine per role.

## metadata.json and dependencies

`site/profiles/metadata.json` only tracks modules that are direct
dependencies of profiles. `.fixtures.yml` can be regenerated with the
`generate_fixtures` rake task.
