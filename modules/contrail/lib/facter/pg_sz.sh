#!/bin/bash
grep Hugepagesize /proc/meminfo | tr -s ' ' | cut -d' ' -f 2
