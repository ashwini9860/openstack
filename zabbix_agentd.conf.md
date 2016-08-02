####In /etc/zabbix/zabbix_agentd.conf add these entries in userparameter section
####create external_scripts folder unser /etc/zabbix & add all scripts their

```
UserParameter=nova-check,/etc/zabbix/external_scripts/check_nova.sh 192.168.0.21
UserParameter=cinder-check,/etc/zabbix/external_scripts/check_cinder.sh 192.168.0.21
UserParameter=image-list-check,/etc/zabbix/external_scripts/check_image-list.sh 192.168.0.21
UserParameter=image-check,/etc/zabbix/external_scripts/check_image.sh 192.168.0.21
UserParameter=neutron-alive-check,/etc/zabbix/external_scripts/check_neutron-alive.sh 192.168.0.21
UserParameter=neutron-host-check,/etc/zabbix/external_scripts/check_neutron-host.sh 192.168.0.21
UserParameter=neutron-check,/etc/zabbix/external_scripts/check_neutron.sh 192.168.0.21
UserParameter=nova-status-check,/etc/zabbix/external_scripts/check_nova-status.sh 192.168.0.21
UserParameter=openstack-service-check,/etc/zabbix/external_scripts/check_openstack-service-info.sh 192.168.0.21
UserParameter=openstack-check,/etc/zabbix/external_scripts/check_openstack.sh 192.168.0.21
UserParameter=volume-check,/etc/zabbix/external_scripts/check_volume.sh 192.168.0.21
