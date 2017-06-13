
class contrail::profile::openstack::horizon(
  $package_sku        = $::contrail::params::package_sku,
) {
  if ($::operatingsystem == 'Centos' or $::operatingsystem == 'Fedora') {
    $local_settings_file = "/etc/openstack-dashboard/local_settings"
    $content_file = "local_settings_centos.erb"
  } else {
    $local_settings_file = "/etc/openstack-dashboard/local_settings.py"
    $content_file = "local_settings.py.erb"
  }
  package { 'openstack-dashboard':
    ensure => latest
  } ->
  file { $local_settings_file :
    ensure => present,
    mode   => '0755',
    group  => root,
    content => template("${module_name}/${content_file}")
  } -> 
  package { 'contrail-openstack-dashboard': 
    ensure => latest
  }
  case $package_sku {
    /14\.0/: {
      notify{"LBaaS plugin for horizon not supported as of now":;}
      $loadbalancer_file = '/usr/lib/python2.7/dist-packages/neutron_lbaas_dashboard/enabled/_1481_project_ng_loadbalancersv2_panel.py'
      $target_lb_file = "/usr/share/openstack-dashboard/openstack_dashboard/enabled/_1481_project_ng_loadbalancersv2_panel.py"

      exec {"copy lbaas file":
        command  => "/bin/cp $loadbalancer_file /usr/share/openstack-dashboard/openstack_dashboard/enabled/",
        provider => shell,
        onlyif   => "test -f $loadbalancer_file",
        unless   => "test -f $target_lb_file"
      } ->
      exec {"lbaas collectstatic":
        command => "echo yes | ./manage.py collectstatic",
        cwd     => "/usr/share/openstack-dashboard",
        provider => shell,
        logoutput => true,
        onlyif   => "test -f $target_lb_file"
      } ->
      exec {"lbaas compress":
        command => "./manage.py compress",
        cwd     => "/usr/share/openstack-dashboard",
        provider => shell,
        logoutput => true,
        onlyif   => "test -f $target_lb_file"
      } ~>
      exec { "Restart apache2":
        command => "service apache2 restart",
        provider => shell,
      }
    }

    /13\.0/: {
      $loadbalancer_file = '/usr/lib/python2.7/dist-packages/neutron_lbaas_dashboard/enabled/_1481_project_ng_loadbalancersv2_panel.py'
      $target_lb_file = "/usr/share/openstack-dashboard/openstack_dashboard/enabled/_1481_project_ng_loadbalancersv2_panel.py"

      exec {"copy lbaas file":
        command  => "/bin/cp $loadbalancer_file /usr/share/openstack-dashboard/openstack_dashboard/enabled/",
        provider => shell,
        onlyif   => "test -f $loadbalancer_file",
        unless   => "test -f $target_lb_file"
      } ->
      exec {"lbaas collectstatic":
        command => "echo yes | ./manage.py collectstatic",
        cwd     => "/usr/share/openstack-dashboard",
        provider => shell,
        logoutput => true,
        onlyif   => "test -f $target_lb_file"
      } ->
      exec {"lbaas compress":
        command => "./manage.py compress",
        cwd     => "/usr/share/openstack-dashboard",
        provider => shell,
        logoutput => true,
        onlyif   => "test -f $target_lb_file"
      } ~>
      exec { "Restart apache2":
        command => "service apache2 restart",
        provider => shell,
      }
    }
  }
}
