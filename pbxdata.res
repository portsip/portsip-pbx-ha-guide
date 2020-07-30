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

on test1 {
  address 192.168.1.141:7789;
  node-id 0;
}

on test2 {
  address 192.168.1.142:7789;
  node-id 1;
}

on test3 {
  address 192.168.1.143:7789;
  node-id 2;
}

connection-mesh {
  hosts test1 test2 test3;
  net {
      use-rle no;
  }
}

}
