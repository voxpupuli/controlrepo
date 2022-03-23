#
# @summary this profile will, in the future, instal Vox Pupuli Tasks
#
# @param deploy_sentry manage the sentry nginx config
# @param deploy_vpt manage the VPT nginx config
# @param deploy_kibana manage the kibana nginx config
#
# @see https://github.com/voxpupuli/vox-pupuli-tasks
#
# @author Tim Meusel <tim@bastelfreak.de>
#
class profiles::vpt (
  Boolean $deploy_sentry = true,
  Boolean $deploy_vpt = true,
  Boolean $deploy_kibana = true
) {
  require profiles::nginx
  # deploy vhosts by hand for now
  if $deploy_sentry {
    file { '/etc/nginx/sites-available/sentry.voxpupu.li.conf':
      ensure  => 'file',
      content => file("${module_name}/sentry.voxpupu.li.conf"),
      notify  => Service['nginx'],
    }
    file { '/etc/nginx/sites-enabled/sentry.voxpupu.li.conf':
      ensure => 'link',
      target => '/etc/nginx/sites-available/sentry.voxpupu.li.conf',
      notify => Service['nginx'],
    }
  }
  if $deploy_vpt {
    file { '/etc/nginx/sites-available/voxpupu.li.conf':
      ensure  => 'file',
      content => file("${module_name}/voxpupu.li.conf"),
      notify  => Service['nginx'],
    }
    file { '/etc/nginx/sites-enabled/voxpupu.li.conf':
      ensure => 'link',
      target => '/etc/nginx/sites-available/voxpupu.li.conf',
      notify => Service['nginx'],
    }
  }
  if $deploy_kibana {
    file { '/etc/nginx/sites-available/kibana.voxpupu.li.conf':
      ensure  => 'file',
      content => file("${module_name}/kibana.voxpupu.li.conf"),
      notify  => Service['nginx'],
    }
    file { '/etc/nginx/sites-enabled/kibana.voxpupu.li.conf':
      ensure => 'link',
      target => '/etc/nginx/sites-available/kibana.voxpupu.li.conf',
      notify => Service['nginx'],
    }
  }
}
