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
    "${matrix_dir}/config/synapse/workers":
      ensure => directory,
      owner  => 991,
      group  => 991,
      mode   => '0555',
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

  # Per-worker configuration files. The official image does not consume
  # SYNAPSE_WORKER_LISTENERS-style environment variables; workers take a
  # second --config-path with worker_app/worker_listeners. Each worker's
  # main port also carries the replication resource, matching the
  # instance_map in homeserver.yaml.
  $workers = {
    'generic_worker1' => { 'port' => 8081, 'resources' => 'client, federation, replication', 'metrics_port' => 9101 },
    'generic_worker2' => { 'port' => 8082, 'resources' => 'client, federation, replication', 'metrics_port' => 9102 },
    'generic_worker3' => { 'port' => 8083, 'resources' => 'federation, replication', 'metrics_port' => 9103 },
    'generic_worker4' => { 'port' => 8084, 'resources' => 'media, client, replication', 'metrics_port' => 9104 },
    'events_persister' => { 'port' => 8085, 'resources' => 'replication', 'metrics_port' => 9105 },
    'receipts_writer' => { 'port' => 8086, 'resources' => 'replication', 'metrics_port' => 9106 },
  }

  $workers.each |$worker_name, $w| {
    file { "${matrix_dir}/config/synapse/workers/${worker_name}.yaml":
      ensure  => file,
      owner   => 991,
      group   => 991,
      mode    => '0444',
      content => @("WORKER"),
        # This file is managed by Puppet.
        worker_app: synapse.app.generic_worker
        worker_name: ${worker_name}
        worker_listeners:
          - type: http
            port: ${w['port']}
            bind_addresses: ['0.0.0.0']
            x_forwarded: true
            resources:
              - names: [${w['resources']}]
          - type: http
            port: ${w['metrics_port']}
            bind_addresses: ['127.0.0.1']
            resources:
              - names: [metrics]
        worker_log_config: /config/log.yaml
        | WORKER
    }
  }

  $worker_config_files = $workers.keys.map |$n| { File["${matrix_dir}/config/synapse/workers/${n}.yaml"] }

  docker_compose { 'matrix-synapse':
    ensure        => present,
    compose_files => ["${matrix_dir}/docker-compose.yml"],
    subscribe     => $worker_config_files + [
      File["${matrix_dir}/docker-compose.yml"],
      File["${matrix_dir}/Dockerfile.synapse"],
      File["${matrix_dir}/.env"],
      File["${matrix_dir}/config/synapse/homeserver.yaml"],
    ],
  }
}
