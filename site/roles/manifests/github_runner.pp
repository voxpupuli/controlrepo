# @summary Configures a node as a GitHub Actions Runner
#
# Configures a node as a GitHub Actions Runner
#
class roles::github_runner {
  include profiles::github_runners
}
