#!/bin/bash
grep MemTotal /proc/meminfo | tr -s ' ' | cut -d' ' -f 2
