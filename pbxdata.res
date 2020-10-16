resource pbxdata {

meta-disk internal;
device /dev/drbd1;
disk /dev/centos/pbxlv;

syncer {
  verify-alg sha1;
}

net {
# allow-two-primaries no;
  after-sb-0pri discard-zero-changes;
  after-sb-1pri discard-secondary;
  after-sb-2pri disconnect;
}
#节点一名字和ip
on pbx01 {
  address host01:7789;
  node-id 0;
}
#节点二名字和ip
on pbx02 {
  address host02:7789;
  node-id 1;
}
#节点三名字和ip
on pbx03 {
  address host03:7789;
  node-id 2;
}

connection-mesh {
  #节点1、2、3名字
  hosts pbx01 pbx02 pbx03;
  net {
      use-rle no;
  }
}

}
