#!/bin/bash

netstat -anp |grep 8140 >> /dev/null
if [ $? == 0 ]; then
  if [ -d "/etc/apache2/sites-enabled" ]; then
    echo true
  else
    echo false
  fi
else
  echo false
fi

