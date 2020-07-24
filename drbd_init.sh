#!/bin/bash
drbdadm create-md pbxdata
drbdadm up pbxdata
ssh $1 "drbdadm create-md pbxdata;drbdadm up pbxdata"
ssh $2 "drbdadm create-md pbxdata;drbdadm up pbxdata"
drbdadm -- --clear-bitmap new-current-uuid pbxdata
drbdadm primary --force pbxdata
mkfs.xfs /dev/drbd1
drbdadm secondary pbxdata