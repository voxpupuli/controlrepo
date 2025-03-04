# @summary Common Let's Encrypt settings
#
# Common Let's Encrypt settings
#
class profiles::lets_encrypt {
  class { 'letsencrypt':
    email          => 'pmc@voxpupuli.org',
    package_ensure => 'latest',
  }
}
