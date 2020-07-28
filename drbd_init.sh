#!/bin/bash
systemctl start drbd
sleep 1
drbdadm create-md pbxdata
drbdadm up pbxdata
ssh $1 "systemctl start drbd; sleep 1;drbdadm create-md pbxdata;drbdadm up pbxdata"
ssh $2 "systemctl start drbd;sleep 1;drbdadm create-md pbxdata;drbdadm up pbxdata"
sleep 10
drbdadm -- --clear-bitmap new-current-uuid pbxdata
drbdadm primary --force pbxdata
mkfs.xfs /dev/drbd1
drbdadm secondary pbxdata
