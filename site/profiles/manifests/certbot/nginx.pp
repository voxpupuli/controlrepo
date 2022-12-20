#
# @summary configures location blocks for nginx
#
# @param domain the domain for the location blocks
#
# @author Tim Meusel <tim@bastelfreak.de>
#
define profiles::certbot::nginx (
  Stdlib::Fqdn $domain = $title,
) {
  include nginx
  nginx::resource::location { "^~ /.well-known/acme-challenge/ - ${domain}":
    server              => $domain,
    www_root            => '/var/lib/letsencrypt/',
    index_files         => [],
    location            => '^~ /.well-known/acme-challenge/',
    location_custom_cfg => { 'default_type' => 'text/plain', },
    ssl                 => false,
    ssl_only            => false,
  }
  nginx::resource::location { "= /.well-known/acme-challenge/ - ${domain}":
    server              => $domain,
    location_cfg_append => { 'return' => '404', },
    index_files         => [],
    location            => '= /.well-known/acme-challenge/',
    ssl                 => false,
    ssl_only            => false,
  }
}
