# Testing roles on real VMs

The rspec suite compiles catalogs; it cannot tell you whether the role
actually converges, starts its services, or survives a second apply. This
rig can: it generates one Vagrant machine per node in `data/nodes/`, gives
each VM the node's real hostname (so hiera classifies it exactly like the
real machine), and applies the current working tree masterless, the same
`puppet apply` + pluginsync path the cloud-init bootstrap uses.

## Use

Needs [Vagrant](https://developer.hashicorp.com/vagrant/install) with any
provider the `bento/ubuntu-24.04` box supports (VirtualBox, Parallels,
VMware Desktop, libvirt; amd64 and arm64 both exist, so Apple Silicon
works natively). Override the box with `CONTROLREPO_BOX` for nodes that
run 22.04 in production.

```console
cd vagrant
vagrant status                 # machines, generated from data/nodes/
vagrant up voxpupu.li          # provision + first apply
./scripts/converge voxpupu.li  # edit the checkout, re-apply (live share)
vagrant destroy -f voxpupu.li  # throw it away
```

The edit loop needs no commits: the checkout is a live read-only share,
`converge` re-syncs it into the VM's environment directory and re-applies.

## Lab overrides

`overrides/<fqdn>.yaml` is appended to the node's hiera data in the VM's
copy only (dummy secrets, `manage_borg: false`, anything a lab cannot
have). `overrides/<fqdn>.hosts` lists extra names to point at 127.0.0.1
for roles that serve more than their own fqdn.

## Expected lab-only failures (not bugs)

- certbot/ACME fails against the fake domains, so nginx stays HTTP-only;
  the profiles' `letsencrypt_directory` fact guards handle this by design
- anything that needs a real secret runs with the dummies from overrides
- `scripts/apply` tolerates puppet exit code 6 (changes + failures)
  because of the ACME failures; read the output for anything that is not
  ACME before calling a run clean
