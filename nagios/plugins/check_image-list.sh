#!/bin/bash
#export OS_USERNAME=admin
#export OS_TENANT_NAME=default
#export OS_PASSWORD=simple123
#export OS_AUTH_URL=http://controller:35357/v3

export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=simple123
export OS_AUTH_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
data=$(openstack image list  2>&1)
rv=$?

if [ "$rv" != "0" ] ; then
    echo $data
    exit $rv
fi

echo "$data" |  grep -v -e '--------' |cut -d '|' -f 3 | sed '1d'
