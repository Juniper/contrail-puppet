define contrail::lib::setup_uid(
    $user_uid,
    $user_group_name,
    $group_gid, 
    $user_home_dir,
    $contrail_logoutput = false) {

  exec {"create-group-${user_group_name}" :
    command => "groupadd  -g $group_gid $user_group_name",
    unless => "getent group $user_group_name | grep -q $group_gid",
    provider  => shell,
    logoutput => $contrail_logoutput,
  } -> 
  exec {"create-user-${name}" :
    command => "useradd -d $user_home_dir -g $user_group_name -r -s /bin/false -u $user_uid $name",
    unless => "id -u $name | grep -q $user_uid",
    provider  => shell,
    logoutput => $contrail_logoutput,
  }
}
