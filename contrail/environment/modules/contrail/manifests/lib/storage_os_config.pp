## This functions configures the cinder.conf, ceph.conf based on pool_data
define contrail::lib::storage_os_config(
  $key,
  $pname,
  $uuid
) {
  notice("POOL_DETAILS: $pname : $key, $uuid")
  ceph_config {
    "client.$pname/keyring" : value => "/etc/ceph/client.$pname.keyring";
  }
  ceph::key {"client.$pname":
    secret          => $key,
    mode            => '0644',
    keyring_path    => "/etc/ceph/client.$pname.keyring"
  }
  #cinder config is not needed for images pool
  if ($pname != "images") {
    cinder_config {
      "rbd-disk-$pname/rbd_pool" : value =>  $pname;
      "rbd-disk-$pname/rbd_user" : value =>  $pname;
      "rbd-disk-$pname/volume_backend_name"      : value => "RBD_$pname";
      "rbd-disk-$pname/rbd_secret_uuid"          : value => "$uuid";
      "rbd-disk-$pname/volume_driver"            : value => "cinder.volume.drivers.rbd.RBDDriver";
      "rbd-disk-$pname/rados_connection_retries" : value => "10000";
    }
    cinder::type{$pname:
      set_key   => "volume_backend_name",
      set_value => "RBD_$pname"
    }
  }
}
