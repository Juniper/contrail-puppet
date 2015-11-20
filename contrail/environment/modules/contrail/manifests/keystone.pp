class contrail::keystone (
  $contrail_keystone_auth_conf = $contrail::params::contrail_keystone_auth_conf
) {
  validate_hash($contrail_keystone_auth_conf)
  create_resources('contrail_keystone_auth_config', $contrail_keystone_auth_conf)
}
