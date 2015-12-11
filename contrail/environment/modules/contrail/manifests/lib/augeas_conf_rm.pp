## This class function is used to remove config for .conf files
## Example of call:
## $redis_config_file = '/etc/redis/redis.conf'
## contrail::lib::augeas_conf_rm { <title>:
##            lens_to_use => $lens,
##            key => $key_to_remove,
##            config_file => $redis_config_file,
## }
##
define contrail::lib::augeas_conf_rm(
          $key,
          $config_file,
          $lens_to_use,
          $match_value = '',
)
{
    if ($match_value != '') {
        augeas {"${config_file}_removing_${key}":
               incl => "${config_file}",
               lens => "${lens_to_use}",
               context => "/files${config_file}",
               changes => "rm ${key}",
               onlyif => "get ${key} == ${match_value}",
        }
    } else {
        augeas{"${config_file}_removing_${key}":
               incl => "${config_file}",
               lens => "${lens_to_use}",
               context => "/files${config_file}",
               changes => "rm ${key}",
        }
    }
}
