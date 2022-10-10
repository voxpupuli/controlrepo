#
# @summary install node_exporter
#
class profiles::node_exporter {
  class { 'prometheus::node_exporter':
    version       => '1.4.0',
    extra_options => '--web.listen-address="127.0.0.1:9100"',
  }
}
