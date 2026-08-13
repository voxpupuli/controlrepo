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
    # Bind-mount targets: without pre-creation Docker makes them
    # root-owned and Synapse (UID 991) cannot write its signing key,
    # media, or logs.
    [
      "${matrix_dir}/data",
      "${matrix_dir}/data/synapse",
      "${matrix_dir}/data/media",
      "${matrix_dir}/logs",
      "${matrix_dir}/logs/synapse",
    ]:
      ensure => directory,
      owner  => 991,
      group  => 991,
      mode   => '0750',
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
    "${matrix_dir}/config/synapse/log.yaml":
      ensure  => file,
      owner   => 991,
      group   => 991,
      mode    => '0444',
      # homeserver.yaml points log_config here; /config is mounted
      # read-only, so Synapse cannot generate it on first start.
      content => @(LOGCONF),
        version: 1
        formatters:
          precise:
            format: '%(asctime)s - %(name)s - %(lineno)d - %(levelname)s - %(request)s - %(message)s'
        handlers:
          console:
            class: logging.StreamHandler
            formatter: precise
        root:
          level: INFO
          handlers: [console]
        disable_existing_loggers: false
        | LOGCONF
    ;
    "${matrix_dir}/config/synapse/homeserver.yaml":
      ensure  => file,
      # The official Synapse image runs as UID 991 and mounts /config
      # read-only; root:0600 is unreadable inside the containers.
      owner   => 991,
      group   => 991,
      mode    => '0400',
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
