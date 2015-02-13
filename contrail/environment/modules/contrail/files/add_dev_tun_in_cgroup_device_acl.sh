#!/bin/bash
grep -q '^cgroup_device_acl' /etc/libvirt/qemu.conf
if [ "$?" -ne 0 ]
then
    grep -q -i -e 'centos' -e 'redhat' /etc/issue
    if [ "$?" -eq 0 ]
    then
	echo "clear_emulator_capabilities = 1" >> /etc/libvirt/qemu.conf
	echo 'user = "root"' >> /etc/libvirt/qemu.conf
	echo 'group = "root"' >> /etc/libvirt/qemu.conf
    fi
    echo 'cgroup_device_acl = [' >> /etc/libvirt/qemu.conf
    echo '    "/dev/null", "/dev/full", "/dev/zero",' >> /etc/libvirt/qemu.conf
    echo '    "/dev/random", "/dev/urandom",' >> /etc/libvirt/qemu.conf
    echo '    "/dev/ptmx", "/dev/kvm", "/dev/kqemu",' >> /etc/libvirt/qemu.conf
    echo '    "/dev/rtc", "/dev/hpet","/dev/net/tun",' >> /etc/libvirt/qemu.conf
    echo ']' >> /etc/libvirt/qemu.conf
    service libvirt-bin restart
fi
