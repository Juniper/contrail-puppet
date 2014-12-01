class contrail::test(
    $test_param = $openstack::config::contrail::zookeeper_ip_list
) inherits openstack::config::contrail {
    $xyz = "String to see if class can have params"
    notify{"zookeeper value is $::openstack::config::contrail::zookeeper_ip_list":;}
    notify{"test_param value is $test_param":;}
    notify{"xyz value is $xyz":;}
    file { "/tmp/test":
        ensure => present,
        content => "this is test file"
    }
}
