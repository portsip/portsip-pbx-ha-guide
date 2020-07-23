resource pbxdata {

meta-disk internal;
device /dev/drbd1;
disk /dev/pbxvg/pbxlv;

syncer {
  verify-alg sha1;
}

net {
# allow-two-primaries no;
  after-sb-0pri discard-zero-changes;
  after-sb-1pri discard-secondary;
  after-sb-2pri disconnect;
}

on node-1 {
  address 192.168.1.90:7789;
  node-id 0;
}

on node-2 {
  address 192.168.1.91:7789;
  node-id 1;
}

on node-3 {
  address 192.168.1.92:7789;
  node-id 2;
}

connection-mesh {
  hosts node-1 node-2 node-3;
  net {
      use-rle no;
  }
}

}
