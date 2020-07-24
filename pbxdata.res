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

on ppptest01 {
  address 192.168.1.93:7789;
  node-id 0;
}

on ppptest02 {
  address 192.168.1.95:7789;
  node-id 1;
}

on ppptest03 {
  address 192.168.1.96:7789;
  node-id 2;
}

connection-mesh {
  hosts ppptest01 ppptest02 ppptest03;
  net {
      use-rle no;
  }
}

}
