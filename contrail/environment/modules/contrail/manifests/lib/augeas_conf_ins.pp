## This class function is used to insert config for .conf files
## Example of call:
## $redis_config_file = '/etc/redis/redis.conf'
## $redis_config = { 'redis_conf' => <key, value hash> }
## $key = <key>
## $value = <value>
## contrail::lib::augeas_conf_ins { 'inserting_${key}_in_${config_file}':
##            key => $key,
##            value => $value,
##            config_file => $redis_config_file,
##            lens_to_use => 'spacevars.lns', ## based on separator, whether conf file has section, etc
## }
##
define contrail::lib::augeas_conf_ins(
          $key,
          $value,
          $config_file,
          $lens_to_use,
)
{
        augeas {"${config_file}_setting_${key}":
               incl => "${config_file}",
               lens => "${lens_to_use}",
               context => "/files${config_file}",
               changes => ["ins ${key} before *[1]" , "set ${key} \"${value}\""],
               onlyif => "get ${key} != ${value}",
        }
}
