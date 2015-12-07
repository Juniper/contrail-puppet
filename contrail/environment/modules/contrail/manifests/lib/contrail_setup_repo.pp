## TODO: Add documentation
define contrail::lib::contrail_setup_repo(
    $contrail_repo_ip,
    $contrail_logoutput = false,
) {
    $contrail_repo_name = $name
    if ($operatingsystem == "Centos" or $operatingsystem == "Fedora") {
        file { "/etc/yum.repos.d/cobbler-config.repo" :
            ensure  => present,
            content => template("contrail-common/contrail-yum-repo.erb")
        }
    }
    if ($operatingsystem == "Ubuntu") {
        apt::source { "contrail_${contrail_repo_name}":
          location => "http://$contrail_repo_ip/contrail/repo/${contrail_repo_name}",
          repos    => 'main',
          release  => 'contrail',
       }
          
	#$pattern1 = "deb http:\/\/$contrail_repo_ip:9003\/contrail\/repo\/$contrail_repo_name contrail main"
	#$pattern2 = "deb http://$contrail_repo_ip:9003/contrail/repo/$contrail_repo_name contrail main"
	#$repo_cfg_file = "/etc/apt/sources.list"
	#file { "/etc/apt/preferences.d/contrail_repo_preferences":
	    #ensure  => present,
	    #mode => 0755,
	    #owner => root,
	    #group => root,
	    #source => "puppet:///modules/$module_name/contrail_repo_preferences"
        #} ->
	#exec { "update-sources-list-$contrail_repo_name" :
	    #command   => "sed -i \"/$pattern1/d\" $repo_cfg_file && echo \"$pattern2\"|cat - $repo_cfg_file > /tmp/out && mv /tmp/out $repo_cfg_file && apt-get update",
	    #unless  => "head -1 $repo_cfg_file | grep -qx \"$pattern2\"",
	    #provider => shell,
	    #logoutput => $contrail_logoutput
	#}
    }
}
