# @summary Sets up a matrix server with synapse, nginx, and letsencrypt
#
# Sets up a highly scalable matrix server with Synapse, Nginx, and Let's Encrypt managed
# via Docker Compose and host-level ACME challenges.
#
# The Docker Compose stack dynamically provisions multiple Synapse workers to distribute
# processing loads (such as media caching, client APIs, and sync handling), specifically
# optimizing for heavy inbound API federation traffic—a crucial requirement since the
# majority of matrix interactions will originate externally from matrix.org rather than
# on this localized host.
#
class roles::matrix_server {
  include nftables::rules::http
  include nftables::rules::https
  include profiles::docker
  include profiles::lets_encrypt
  include profiles::matrix
  include profiles::nginx
}
