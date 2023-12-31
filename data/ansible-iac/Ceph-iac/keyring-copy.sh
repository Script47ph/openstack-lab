#!/bin/bash
sudo ceph osd pool create volumes
sudo ceph osd pool create images
sudo ceph osd pool create backups
sudo ceph osd pool create vms

sudo rbd pool init volumes
sudo rbd pool init images
sudo rbd pool init backups
sudo rbd pool init vms

sudo ceph auth get-or-create client.glance mon 'profile rbd' osd 'profile rbd pool=images' mgr 'profile rbd pool=images'
sudo ceph auth get-or-create client.cinder mon 'profile rbd' osd 'profile rbd pool=volumes, profile rbd pool=vms, profile rbd-read-only pool=images' mgr 'profile rbd pool=volumes, profile rbd pool=vms'
sudo ceph auth get-or-create client.cinder-backup mon 'profile rbd' osd 'profile rbd pool=backups' mgr 'profile rbd pool=backups'

for i in {1..3}
do
sudo cat /etc/ceph/ceph.client.admin.keyring | ssh control-0$i "sudo tee /etc/ceph/ceph.client.admin.keyring"
sudo cat /etc/ceph/ceph.client.admin.keyring | ssh compute-0$i "sudo tee /etc/ceph/ceph.client.admin.keyring"
sudo cat /etc/ceph/ceph.conf | ssh control-0$i "sudo tee /etc/ceph/ceph.conf"
sudo cat /etc/ceph/ceph.conf | ssh compute-0$i "sudo tee /etc/ceph/ceph.conf"
done

for i in {1..3}
do
sudo ceph auth get-or-create client.glance | ssh control-0$i "sudo tee /etc/ceph/ceph.client.glance.keyring"
sudo ceph auth get-or-create client.cinder | ssh control-0$i "sudo tee /etc/ceph/ceph.client.cinder.keyring"
sudo ceph auth get-or-create client.cinder-backup | ssh control-0$i "sudo tee /etc/ceph/ceph.client.cinder-backup.keyring"
sudo ceph auth get-or-create client.glance | ssh compute-0$i "sudo tee /etc/ceph/ceph.client.glance.keyring"
sudo ceph auth get-or-create client.cinder | ssh compute-0$i "sudo tee /etc/ceph/ceph.client.cinder.keyring"
sudo ceph auth get-or-create client.cinder-backup | ssh compute-0$i "sudo tee /etc/ceph/ceph.client.cinder-backup.keyring"
done

sudo ceph config set mon mon_warn_on_insecure_global_id_reclaim false
sudo ceph config set mon mon_warn_on_insecure_global_id_reclaim_allowed false