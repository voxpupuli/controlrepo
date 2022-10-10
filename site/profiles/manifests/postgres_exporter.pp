#
# @summary installs a postgres exporter
#
class profiles::postgres_exporter {
  class { 'prometheus::postgres_exporter':
    version              => '0.11.1',
    user                 => 'postgres',
    group                => 'postgres',
    postgres_auth_method => 'custom',
    manage_user          => false,
    manage_group         => false,
    options              => '--web.listen-address="127.0.0.1:9187"',
    data_source_custom   => { 'DATA_SOURCE_NAME' => 'user=postgres host=/var/run/postgresql/ sslmode=disable', },
  }
}
