# @summary A wrapper profile to set up Matrix Synapse and its required services
#
# This profile serves as the entry point for configuring the Matrix server. It configures
# Nginx as a reverse proxy, provisions SSL certificates, and orchestrates the Synapse
# Docker backend with Hetzner S3 object storage for media eviction and federation routing.
#
# @param sensitive_postgres_password The password for the Synapse PostgreSQL database.
# @param sensitive_macaroon_secret_key The secret key used for signing macaroons.
# @param sensitive_form_secret The secret key used for form validation.
# @param sensitive_s3_access_key The access key for the S3 object storage bucket.
# @param sensitive_s3_secret_key The secret key for the S3 object storage bucket.
# @param s3_bucket The name of the S3 bucket to act as the media store.
# @param s3_region The region where the S3 bucket is hosted.
# @param s3_endpoint The endpoint URL for the S3 object storage.
#
class profiles::matrix (
  Sensitive[String] $sensitive_postgres_password,
  Sensitive[String] $sensitive_macaroon_secret_key,
  Sensitive[String] $sensitive_form_secret,
  Sensitive[String] $sensitive_s3_access_key,
  Sensitive[String] $sensitive_s3_secret_key,
  String $s3_bucket,
  String $s3_region,
  String $s3_endpoint,
) {
  include profiles::matrix::nginx
  include profiles::matrix::synapse

  # nftables::rules::docker_ce covers forwarded bridge traffic, but
  # host-originated egress (nginx and docker-proxy dialing the published
  # container ports) traverses the output chain, whose default policy is
  # drop — without this, every proxied request times out.
  nftables::rule { 'default_out-matrix0':
    content => 'oifname "matrix0" accept',
  }
}
