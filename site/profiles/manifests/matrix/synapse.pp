# @summary Docker Compose deployment for Matrix Synapse
#
# This class ensures the presence of the `/opt/matrix-synapse` directory and coordinates
# the templated layout of `.env` and `homeserver.yaml` files holding sensitive deployment
# secrets securely. Finally, it uses `puppetlabs-docker` to orchestrate the Docker Compose
# multi-worker stack based on the provided configuration.
#
class profiles::matrix::synapse {
  $matrix_dir = '/opt/matrix-synapse'

  file {
    default:
      owner => 'root',
      group => 'root',
    ;
    $matrix_dir:
      ensure => directory,
      mode   => '0750',
    ;
    [
      "${matrix_dir}/config",
      "${matrix_dir}/config/synapse",
    ]:
      ensure => directory,
    ;
    "${matrix_dir}/docker-compose.yml":
      ensure => file,
      source => 'puppet:///modules/profiles/matrix/docker-compose.yml',
    ;
    "${matrix_dir}/Dockerfile.synapse":
      ensure => file,
      source => 'puppet:///modules/profiles/matrix/Dockerfile.synapse',
    ;
    "${matrix_dir}/.env":
      ensure  => file,
      mode    => '0600',
      content => epp('profiles/matrix/env.epp', {
        'postgres_password' => $profiles::matrix::sensitive_postgres_password,
      }),
    ;
    "${matrix_dir}/config/synapse/homeserver.yaml":
      ensure  => file,
      mode    => '0600',
      content => epp('profiles/matrix/homeserver.yaml.epp', {
        'macaroon_secret_key' => $profiles::matrix::sensitive_macaroon_secret_key,
        'form_secret'         => $profiles::matrix::sensitive_form_secret,
        'postgres_password'   => $profiles::matrix::sensitive_postgres_password,
        's3_bucket'           => $profiles::matrix::s3_bucket,
        's3_region'           => $profiles::matrix::s3_region,
        's3_endpoint'         => $profiles::matrix::s3_endpoint,
        's3_access_key'       => $profiles::matrix::sensitive_s3_access_key,
        's3_secret_key'       => $profiles::matrix::sensitive_s3_secret_key,
      }),
    ;
  }

  docker_compose { 'matrix-synapse':
    ensure        => present,
    compose_files => ["${matrix_dir}/docker-compose.yml"],
    subscribe     => [
      File["${matrix_dir}/docker-compose.yml"],
      File["${matrix_dir}/Dockerfile.synapse"],
      File["${matrix_dir}/.env"],
      File["${matrix_dir}/config/synapse/homeserver.yaml"],
    ],
  }
}
