#!/bin/bash

# set hostname
sudo hostname $(cat /etc/hostname)

# mount disk.img
# note: /var/lib/docker is ephemeral
rm -rf /data/disk.img &> /dev/null
total_space=$(df --output=size /data | tail -n 1)
total_space_gb=$(echo "($total_space / 1024 / 1024) + 0.5" | bc)
total_space_gb_int=$(printf "%.0f" "$total_space_gb")

sudo truncate -s "$((total_space_gb_int - 1))G" /data/disk.img
sudo mkfs.ext4 /data/disk.img
sudo mount /data/disk.img /var/lib/docker; 

# switch to legacy iptables
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy

# start dockerd 
sudo dockerd-entrypoint.sh &

RUNNER_VOLUME_DIR="/home/runner"
CONFIG_FILE="$RUNNER_VOLUME_DIR/.runner"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Copying actions-runner to /home/runner..."
  sudo cp -a /actions-runner/* /home/runner/
  sudo chown runner:docker -R /home/runner

  echo "Configuring the GitHub runner..."
  cd $RUNNER_VOLUME_DIR
  ./config.sh --unattended --replace --name ${RUNNER_NAME} --url $REPO_URL --token $RUNNER_TOKEN
else
  echo "Runner is already configured. Skipping configuration."
fi

# run CMD
cd $RUNNER_VOLUME_DIR
exec "$@"
