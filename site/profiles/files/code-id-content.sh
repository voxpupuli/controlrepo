#!/bin/bash

# This file is managed by openvox

set -e
if [[ $# < 3 ]]; then
  echo Expected environment, code-id, file-path >&2
  exit 1
fi
cd /etc/puppetlabs/code/environments/"$1" && git show "$2":"$3"
