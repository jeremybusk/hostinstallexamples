#!/bin/bash
set -ex

# Simple Ubuntu install script for vm/container tool usage.
# Requirements, base install from Ubuntu 18.04 that is using md for raid to manage system.

sudo apt-get udpate
sudo apt-get install -y zfsutils-linux

# Needed when zpool doesn't get imported becasue of lag. 15 secs is generous wait
sudo sed -i "s/^ZFS_INITRD_POST_MODPROBE_SLEEP.*/ZFS_INITRD_POST_MODPROBE_SLEEP='15'/g" /etc/default/zfs
sudo update-initramfs -u
sudo update-grub

# Setup zpool with cache/logs from vdevs
zpool create -f tank mirror sdd sde mirror sdf sdg mirror sdh sdi mirror sdj sdk
sudo zpool add tank mirror nvme2n1 nvme3n1
sudo zpool add tank log mirror nvme0n1 nvme1n1
sudo zpool add tank cache nvme2n1 nvme3n1

# ZFS prep to have default docker, libvirt and lxd on zfs datasets
sudo zfs create tank/docker
sudo zfs set mountpoint=/var/lib/docker tank/docker

sudo zfs create tank/libvirt
sudo zfs set mountpoint=/var/lib/libvirt tank/libvirt

sudo systemctl stop lxd lxd.socket
sudo rm -Rf /var/lib/lxd
sudo zfs create tank/lxd
sudo zfs set mountpoint=/var/lib/lxd tank/lxd

sudo zfs mount -a

systemctl start lxd

# Install docker-ce
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io

# install qemu-kvm+libvirt
sudo apt-get install -y libguestfs-tools qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils virt-manager

# install useful tools
sudo apt-get install -y lintian curl wget git iotop sysstat fio
