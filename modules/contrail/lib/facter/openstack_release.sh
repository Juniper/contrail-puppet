#!/bin/bash

OPENSTACK_VERSION=`/usr/bin/nova-manage version`
OPENSTACK_RELEASE='NOT_SUPPORTED'
if [[ "${OPENSTACK_VERSION}" =~ 2015.1.* ]]
then
   OPENSTACK_RELEASE='kilo'
fi
if [[ "${OPENSTACK_VERSION}" =~ 2014.2.* ]]
then
 OPENSTACK_RELEASE='juno'
fi
if [[ ${OPENSTACK_VERSION} =~ 2014.1.* ]] ;
then
  OPENSTACK_RELEASE='icehouse';
fi
if [[ ${OPENSTACK_VERSION} =~ 2013.2.* ]] ;
then
  OPENSTACK_RELEASE='havana';
fi
echo ${OPENSTACK_RELEASE}
