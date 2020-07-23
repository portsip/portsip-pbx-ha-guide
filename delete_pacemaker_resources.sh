#!/bin/bash
pcs  resource delete drbd_devpath_master >/dev/null 2>&1
pcs resource delete vip >/dev/null 2>&1
pcs resource delete src_pkt_ip  >/dev/null 2>&1
pcs resource delete datapath_fs >/dev/null 2>&1
pcs resource delete  pbx >/dev/null 2>&1
pcs resource cleanup  >/dev/null 2>&1

