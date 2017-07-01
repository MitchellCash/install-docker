#!/bin/sh
set -e

do_token=""
do_volume_name="bitcoin-data-$(uuidgen)"
do_droplet_id="$(curl http://169.254.169.254/metadata/v1/id)"

# Configure Digital Ocean volume
#
# Create a new volume
curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer ${do_token}" -d '{"size_gigabytes":150, "name": "'${do_volume_name}'", "description": "", "region": "sgp1"}' "https://api.digitalocean.com/v2/volumes"
sleep 20

# Get volume ID
do_volume_id="$(curl -X GET -H "Content-Type: application/json" -H "Authorization: Bearer ${do_token}" "https://api.digitalocean.com/v2/volumes?name=${do_volume_name}&region=sgp1" | awk '{ print substr( $0,20,36 ) }')"

# Attach volume to droplet
curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer ${do_token}" -d '{"type": "attach", "droplet_id": '${do_droplet_id}', "region": "sgp1"}' "https://api.digitalocean.com/v2/volumes/${do_volume_id}/actions"
sleep 20

# Format the volume with ext4
# Warning: This will erase all data on the volume. Only run this command on a volume with no existing data
sudo mkfs.ext4 -F /dev/disk/by-id/scsi-0DO_Volume_${do_volume_name}

# Create a mount point under /mnt
sudo mkdir -p /mnt/${do_volume_name}

# Mount the volume
sudo mount -o discard,defaults /dev/disk/by-id/scsi-0DO_Volume_${do_volume_name} /mnt/${do_volume_name}

# Change fstab so the volume will be mounted after a reboot
echo /dev/disk/by-id/scsi-0DO_Volume_${do_volume_name} /mnt/${do_volume_name} ext4 defaults,nofail,discard 0 0 | sudo tee -a /etc/fstab

# Create a bitcoind-data volume to persist the bitcoind blockchain data
docker volume create --name=bitcoind-data --opt device=/mnt/${do_volume_name} --opt o=bind
