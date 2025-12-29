class profiles::openvoxview {
  quadlets::quadlet { 'openvoxview.container':
    ensure          => present,
    unit_entry      => {
      'Description' => 'Run OpenVoxView',
    },
    service_entry   => {
      'TimeoutStartSec' => '900',
    },
    container_entry => {
      'Image' => 'ghcr.io/voxpupuli/openvoxview:v0.1.25',
      # https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html#publishport
      # 8080 is used by OpenVoxDB by default
      'PublishPort' => '8181:8080',
    },
    install_entry   => {
      'WantedBy' => 'default.target',
    },
    active          => true,
  }

}
