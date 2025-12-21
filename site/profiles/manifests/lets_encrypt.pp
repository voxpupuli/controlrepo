# @summary Common Let's Encrypt settings
#
# Common Let's Encrypt settings
#
class profiles::lets_encrypt {
  class { 'letsencrypt':
    email          => 'pmc@voxpupuli.org',
    package_ensure => 'latest',
  }
  systemd::dropin_file { 'restart-and-verbose.conf':
    unit    => 'certbot.service',
    content => "[Service]\nExecStart=\nExecStart=/usr/bin/certbot --verbose renew --no-random-sleep-on-renew\nExecStartPost=/bin/systemctl reload-or-restart nginx\n",
  }
}
