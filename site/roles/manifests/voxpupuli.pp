#
# This role encompasses the various applications that makeup the host at voxpupu.li
#
class roles::voxpupuli {
  include profiles::grafana
  include profiles::node_exporter
  include profiles::postgres_exporter
  include profiles::prometheus
  include profiles::puppetcode
  include profiles::puppetmodule
  include profiles::vpt
}
