class openstack::common::contrail {
    #include openstack::config::contrail
    # Create repository config on target.
    contrail::lib::contrail-setup-repo{ contrail_repo:
        contrail_repo_name => hiera("contrail::common::contrail_repo_name"),
        contrail_repo_ip => hiera("contrail::common::contrail_repo_ip")
    } ->

    contrail::lib::contrail-install-repo{ install_repo:
        contrail_repo_type => "contrail-ubuntu-package"
    } ->

    exec{"/usr/bin/apt-get update":
    }

    # custom type common for all roles.
    class {'::contrail::common':
        require => Exec['/usr/bin/apt-get update']
    }
}
