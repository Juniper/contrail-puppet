#!/bin/bash
grep HugePages_total /proc/meminfo | tr -s ' ' | cut -d' ' -f 2
