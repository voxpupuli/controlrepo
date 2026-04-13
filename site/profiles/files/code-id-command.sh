#!/bin/bash

# This file is managed by puppet

set -e
if [[ -z "$1" ]]; then
  echo Expected an environment >&2
  exit 1
fi

# workaround for newer git
if ! grep -q "/etc/puppetlabs/code/environments/${1}" .gitconfig; then
  git config --global --add safe.directory "/etc/puppetlabs/code/environments/${1}"
fi
cd /etc/puppetlabs/code/environments/"$1" && git rev-parse HEAD
