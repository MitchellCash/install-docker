#!/bin/sh
set -e

curl -s -o- https://releases.rancher.com/install-docker/1.12.sh | bash

curl -s -o- http://your_server_ip_or_fqdn/do-provision-volume.sh | bash
