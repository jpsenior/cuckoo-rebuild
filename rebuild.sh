#!/bin/bash

#JP Senior 14/04/2015

templatevm="cuckoo-template"
templatedisk="cuckoo-template1.qcow2"
storagepath="/opt/vm"
waittime=180

vms="cuckoo1 cuckoo2 cuckoo3 cuckoo4 cuckoo5 cuckoo6 cuckoo7 cuckoo8 cuckoo9 cuckoo10 cuckoo11 cuckoo12"

echo "Destroy existing linked images"
rm -rf $storagepath/base.img

echo "Create linked base clone"
qemu-img create -f qcow2 -b $storagepath/$templatedisk $storagepath/base.img

#1 = number (multiplied by 5)
#2 = vm name
function boot() {
  echo "Starting VM $v and waiting 180 seconds to snapshot"
  echo "Staggering by 15 seconds each"
  sleep $(($1*20))

  virsh start $2
  sleep $waittime
  virsh snapshot-create-as $2 "cuckoo start"
  sleep 10
  echo "Shutting down VM $2 for cuckoo"
  virsh destroy $2
}

m=0
for v in $vms;
do
  m=$((m+1))
  #store padded VM 'count' eg 5 = 05 and convert to hex eg "10" -> "0a"
  printf -v mac "%0.2x" $m
  echo "Destroy (shutdown) VM on $v"
  virsh destroy $v
  echo "Delete VM, Snapshot, metadata, and all storage for $v"
  virsh undefine $v --snapshots-metadata --remove-all-storage
  echo "Create linked clone disk for VM $v"
  qemu-img create -f qcow2 -b $storagepath/base.img $storagepath/${v}.img
  echo "Clone new VM $v"
  virt-clone -o $templatevm -n $v -m 52:54:00:5c:01:$mac
  echo "Modify disk on new cloned VM $v"
  virt-xml $v --edit --disk $storagepath/${v}.img
  #boot $m $v &
done

exit
