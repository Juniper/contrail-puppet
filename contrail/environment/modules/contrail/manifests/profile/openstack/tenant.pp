define contrail::profile::openstack::tenant (
  $description,
  $enabled = true,
) {

  keystone_tenant { "$name":
    ensure      => present,
    description => $description,
    enabled     => $enabled,
  }

}
