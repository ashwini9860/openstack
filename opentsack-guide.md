#Openstack installation ubuntu 14.04 using mitaka:-

The OpenStack project is an open source cloud computing platform that supports all types of cloud environments. The project aims for simple implementation, massive scalability, and a rich set of features.

##Hardware requirements:-

![](/Users/ashwiniChaudhari/Downloads/hard-openstack.png)


The following minimum requirements should support a proof-of-concept environment with core services:-

- Controller Node: 1 processor, 4 GB memory, and 5 GB storage
- Compute Node: 1 processor, 2 GB memory, and 10 GB storage

##Network layout:-

![](/Users/ashwinichaudhari/Downloads/networkl-openstack.png)

**Note:- We set controller & compute node only**

--------------

##Environment setup:-
---------
###configure Network Interfaces:-
----------
####Controller Node:-

- Configure the first interface as the management interface:
- Edit /etc/network/interfaces

|  |  |
|---------- |------------| 
| IP address | 192.168.0.21 | 
| Network mask | 255.255.255.0 (or /24) |
| Default gateway| 192.168.0.1 |
| Broadcast | 192.168.0.255 |
| DNS nameserver | 8.8.8.8 |

- The provider interface uses a special configuration without an IP address assigned to it. Configure the second interface as the provider interface:

```
# The provider network interface
auto INTERFACE_NAME
iface INTERFACE_NAME inet manual
up ip link set dev $IFACE up
down ip link set dev $IFACE down
```
**Note:-** replace "INTERFACE_NAME" your interface 

- Reboot system

-------
###Configure Name Resolution:-
-------
####Controller Node:-
- set host name entry for controller & compute node in /etc/hosts:-

####Compute Node :-

Repeat above 2 procedure same as controller node just change values according to your environment.

-----
###Network Time Protocol (NTP):-
----
####Controller Node:-
- install Chrony, an implementation of NTP, to properly synchronize services among nodes.

- install packages
 		
 		apt-get install chrony
- Edit the /etc/chrony/chrony.conf file and add, change, or remove the following keys as necessary for your environment

		server 192.168.0.21 iburst 
 
- Restart the NTP service:

 		service chrony restart
 		
####Compute Node:-
 
- install packages

 		apt-get install chrony
 	
- Edit the /etc/chrony/chrony.conf file and comment out or remove all but one server key. Change it to reference the controller node:
 
		server controller iburst	 		
		 
- Restart the NTP service:
 
	 	service chrony restart

####Verify Operation:-
- Run this command on all node:

		chronyc sources
---------
###Install OpenStack packages:-
-------

**Perform these procedures on all nodes.**

- Enable the OpenStack repository

		apt-get install softwareA-properties-common
		add-apt-repository cloud-archive:mitaka

- Finalize the installation, upgrade packages on your host

		apt-get update && apt-get dist-upgrade
- Install the OpenStack client:

		 apt-get install python-openstackclient
  
---------

###Install SQL database:-
-------
####Controller Node:-

The database typically runs on the controller node. The procedures in this guide use MariaDB or MySQL depending on the distribution.

- Install the packages:

		apt-get install mariadb-server python-pymysql
- Create and edit the /etc/mysql/conf.d/openstack.cnf file and complete the following actions:

  In the [mysqld] section, set the bind-address key to     the management IP address of the controller node to enable access by other nodes via the management network:

 ```
[mysqld]
bind-address = 192.168.0.21
```

- In the [mysqld] section, set the following keys to enable useful options and the UTF-8 character set:

 ```
[mysqld]
default-storage-engine = innodb
innodb_file_per_table
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
```
- Restart the database service:
- Secure the database service by running the mysql_secure_installation script.

	 	mysql_secure_installation
	 		
------
###Install NoSQL database:-
-----
####Controller Node:-
- Install the MongoDB packages:
		
		apt-get install mongodb-server mongodb-clients python-pymongo

- Edit the /etc/mongodb.conf file and complete the following actions:

 Configure the bind_ip key to use the management interface IP address of the controller node. 
	
 ```
 bind_ip = 192.168.0.21
 
 ```
- Restart service:

	   	service mongodb start	
		 	 
---------
###Message queue:-
--------
####Controller Node:-

OpenStack uses a message queue to coordinate operations and status information among services. The message queue service typically runs on the controller node

- Install the package:

		apt-get install rabbitmq-server	 
- Add the openstack user:

 ```
rabbitmqctl add_user openstack RABBIT_PASS	
```
Replace RABBIT_PASS with a suitable password.

- Permit configuration, write, and read access for the openstack user:

		rabbitmqctl set_permissions openstack ".*" ".*" ".*"

----------
###Memcached:-
----------
####Controller Node:-
The Identity service authentication mechanism for services uses Memcached to cache tokens. The memcached service typically runs on the controller node.

- Install the packages:

		apt-get install memcached python-memcache
		
- Edit the /etc/memcached.conf file and configure the service to use the management IP address of the controller node to enable access by other nodes via the management network:

		-l 192.168.0.21
- Restart the Memcached service:

		 service memcached restart

-------

##Identity Service:-
------
####Controller Node:-
This section describes how to install and configure the OpenStack Identity service, code-named keystone, on the controller node. For performance, this configuration deploys Fernet tokens and the Apache HTTP server to handle requests.

**Prerequisites**

- To create the database, complete the following action
Use the database access client to connect to the database server as the root user:

		mysql -u root -p
- Create the keystone database:

		CREATE DATABASE keystone;
- Grant proper access to the keystone database:

 ```				
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' \
  IDENTIFIED BY 'KEYSTONE_DBPASS';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' \
  IDENTIFIED BY 'KEYSTONE_DBPASS';
```
Replace KEYSTONE_DBPASS with a suitable password.
- Exit the database access client.
- Generate a random value to use as the administration token during initial configuration:

		openssl rand -hex 10
 save this value for future use
 
**Install and configure components**

- Disable the keystone service from starting automatically after installation:

		echo "manual" > /etc/init/keystone.override
-  install the packages:
	 
	  	 apt-get install keystone apache2 libapache2-mod-wsgi		
- Edit the /etc/keystone/keystone.conf file and complete the following actions:

 ```
 [DEFAULT]
admin_token = ADMIN_TOKEN		
 [database]
connection = mysql+pymysql://keystone:KEYSTONE_DBPASS@controller/keystone
[token]
provider = fernet				
```
Replace ADMIN_TOKEN with the random value that you generated in a previous step

 Replace KEYSTONE_DBPASS with the password you chose for the database.		
- Populate the Identity service database:

		su -s /bin/sh -c "keystone-manage db_sync" keystone
- Initialize Fernet keys:

		 keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone

**Configure the Apache HTTP server**

- Edit the /etc/apache2/apache2.conf file and configure the ServerName option to reference the controller node:
		
		ServerName controller
- Create the /etc/apache2/sites-available/wsgi-keystone.conf file with the following content:

 ```
 Listen 5000
 Listen 35357

 <VirtualHost *:5000>
    WSGIDaemonProcess keystone-public processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-public
    WSGIScriptAlias / /usr/bin/keystone-wsgi-public
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    ErrorLogFormat "%{cu}t %M"
    ErrorLog /var/log/apache2/keystone.log
    CustomLog /var/log/apache2/keystone_access.log combined

    <Directory /usr/bin>
        Require all granted
    </Directory>
</VirtualHost>

	<VirtualHost *:35357>
 	WSGIDaemonProcess keystone-admin processes=5 threads=1      	user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-admin
    WSGIScriptAlias / /usr/bin/keystone-wsgi-admin
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    ErrorLogFormat "%{cu}t %M"
    ErrorLog /var/log/apache2/keystone.log
    CustomLog /var/log/apache2/keystone_access.log combined

    <Directory /usr/bin>
        Require all granted
    </Directory>
</VirtualHost>
```		
		 		
- Enable the Identity service virtual hosts:
 
 		 ln -s /etc/apache2/sites-available/wsgi-keystone.conf /etc/apache2/sites-enabled
- Restart the Apache HTTP server:

		service apache2 restart
		
- By default, the Ubuntu packages create an SQLite database, remove it:-
 
 		 rm -f /var/lib/keystone/keystone.db
 
 **Create the service entity and API endpoints**
 
- Configure the authentication token:

		export OS_TOKEN=ADMIN_TOKEN	
Replace ADMIN_TOKEN with the authentication token that you generated 		 		

- Configure the endpoint URL:

		 export OS_URL=http://controller:35357/v3
- Configure the Identity API version:

		export OS_IDENTITY_API_VERSION=3
- Create the service entity for the Identity service:

 ```
	openstack service create \
  --name keystone --description "OpenStack Identity" identity				 		
 ```
 
- Create the Identity service API endpoints: 
 
 ```
  openstack endpoint create --region RegionOne \
  identity public http://controller:5000/v3
  ```
  
  ```
  openstack endpoint create --region RegionOne \
  identity internal http://controller:5000/v3
  ```
  
  ```
   openstack endpoint create --region RegionOne \
  identity admin http://controller:35357/v3
  ```
  **Create a domain, projects, users, and roles**
  
- Create the default domain:

		openstack domain create --description "Default Domain" default
- Create an administrative project, user, and role for administrative operations in your environment:

	- Create the admin project:

		```
		openstack project create --domain default \
  --description "Admin Project" admin
  ```
   - Create the admin user:
  
  		```  
    openstack user create --domain default \
  --password-prompt admin
    ```
  - Create the admin role:

     ```
     openstack role create admin
     ```
  - Add the admin role to the admin project and user:
   
   		 	openstack role add --project admin --user admin admin  

- This guide uses a service project that contains a unique user for each service that you add to your environment. Create the service project:

	```
	openstack project create --domain default \
  --description "Service Project" service	```
  
- Regular (non-admin) tasks should use an unprivileged project and user. As an example, this guide creates the demo project and user.
     - Create the demo project:
     
     ```
     openstack project create --domain default \
  --description "Demo Project" demo
     ```	  
     - Create the demo user:
      
      ```
      openstack user create --domain default \
  --password-prompt demo
  ```
  - Create the user role:

			openstack role create user
	- Add the user role to the demo project and user:
	 
	 		openstack role add --project demo --user demo user

**Verify operation**

- For security reasons, disable the temporary authentication token mechanism:

 Edit the /etc/keystone/keystone-paste.ini file and remove admin_token_auth from the [pipeline:public_api], [pipeline:admin_api], and [pipeline:api_v3] sections.

- Unset the temporary OS_TOKEN and OS_URL environment variables:

		unset OS_TOKEN OS_URL
- As the admin user, request an authentication token:

   ```
   openstack --os-auth-url http://controller:35357/v3 \
  --os-project-domain-name default --os-user-domain-name default \
  --os-project-name admin --os-username admin token issue
  ```
- As the demo user, request an authentication token:

  ```
  openstack --os-auth-url http://controller:5000/v3 \
  --os-project-domain-name default --os-user-domain-name default \
  --os-project-name demo --os-username demo token issue
  ```
  
**Create OpenStack client environment scripts** 

- Edit the admin-openrc file and add the following content:

 ```
 export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=ADMIN_PASS
export OS_AUTH_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
```
Replace ADMIN_PASS with the password you chose for the admin user in the Identity service.

- Edit the demo-openrc file and add the following content:


  ```
  export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=DEMO_PASS
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
 ```
 
- Load the admin-openrc file to populate environment variables with the location of the Identity service and the admin project and user credentials:

		. admin-openrc
- Request an authentication token:
	
		openstack token issue
	
-------
##Image Service
-------		
####Controller Node:-
The Image service (glance) enables users to discover, register, and retrieve virtual machine images.

**Prerequisites**

- To create the database, complete these steps:

  - Use the database access client to connect to the database server as the root user:
   
   		 	mysql -u root -p
   - Create the glance database:
   
   			CREATE DATABASE glance;
   	- Grant proper access to the glance database:
   	
   	 ```
   	 GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' \
  IDENTIFIED BY 'GLANCE_DBPASS';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' \
  IDENTIFIED BY 'GLANCE_DBPASS';
```
Replace GLANCE_DBPASS with a suitable password.
- Source the admin credentials to gain access to admin-only CLI commands:
 		
 		. admin-openrc
- To create the service credentials, complete these steps:

  - Create the glance user:
    
   			openstack user create --domain default --password-prompt glance		

  - Add the admin role to the glance user and service project:

   			openstack role add --project service --user glance admin

 - Create the glance service entity:

     ```
     openstack service create --name glance \
  --description "OpenStack Image" image
    ```
  - Create the Image service API endpoints:
   
     ```
      openstack endpoint create --region RegionOne \
  image public http://controller:9292
    ```
    
      ```
       openstack endpoint create --region RegionOne \
  image internal http://controller:9292
    ```
     ```
     openstack endpoint create --region RegionOne \
  image admin http://controller:9292
     ```

**Install and configure components**   

- Install the packages:

		apt-get install glance
- Edit the /etc/glance/glance-api.conf file and complete the following actions:

	```
	[database]
connection = mysql+pymysql://glance:GLANCE_DBPASS@controller/glance   

  [keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = glance
password = GLANCE_PASS
  
  [paste_deploy]
flavor = keystone				 				

  [glance_store]
stores = file,http
default_store = file
filesystem_store_datadir = /var/lib/glance/images/ 
 ```
 Replace GLANCE_DBPASS with the password you chose for the Image service database.

	Replace GLANCE_PASS with the password you chose for the glance user in the Identity service.

- Edit the /etc/glance/glance-registry.conf file and complete the following actions:

  ```
  [database]
connection = mysql+pymysql://glance:GLANCE_DBPASS@controller/glance
 	
 	
 	[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = glance
password = GLANCE_PASS

  [paste_deploy]
flavor = keystone			

  ```
  Replace GLANCE_DBPASS with the password you chose for the Image service database.
  
   Replace GLANCE_PASS with the password you chose for the glance user in the Identity service.
  
- Populate the Image service database:

		su -s /bin/sh -c "glance-manage db_sync" glance

- Restart the Image services:

		service glance-registry restart
		service glance-api restart
				   
**Verify operation**		

- Source the admin credentials to gain access to admin-only CLI commands:

		. admin-openrc
- Download the source image:
 		
 		wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
- Upload the image to the Image service using the QCOW2 disk format, bare container format, and public visibility so all projects can access it:

	
		openstack image create "cirros" \
  		--file cirros-0.3.4-x86_64-disk.img \
  		--disk-format qcow2 --container-format bare \
  		--public
  	
- Confirm upload of the image and validate attributes:
 
 		openstack image lis
 		
-----				 

##Compute Service:-

------
Use OpenStack Compute to host and manage cloud computing systems. OpenStack Compute is a major part of an Infrastructure-as-a-Service (IaaS) system.

####Controller Node:-

**Prerequisites**

- To create the databases, complete these steps:
   - Use the database access client to connect to the database server as the root user:
    				
    		mysql -u root -p
   - Create the nova_api and nova databases:

			CREATE DATABASE nova_api;
			CREATE DATABASE nova; 		
   - Grant proper access to the databases:
   
      ```   
        GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' \
  		IDENTIFIED BY 'NOVA_DBPASS';
	   ```		
		```
		GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' \
  		IDENTIFIED BY 'NOVA_DBPASS';
		```	
		```
		GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' \
  		IDENTIFIED BY 'NOVA_DBPASS';
		```
		```
		GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' \
  		IDENTIFIED BY 'NOVA_DBPASS';
  		```
  		Replace NOVA_DBPASS with a suitable password.
  	- Exit database.
- Source the admin credentials to gain access to admin-only CLI commands:

		. admin-openrc
- To create the service credentials, complete these steps:
   - Create the nova user:
   
      ```
      openstack user create --domain default \
  --password-prompt nova
    ```
   - Add the admin role to the nova user:

	   		openstack role add --project service --user nova admin 		
	- Create the nova service entity:
	 
	   ```
	   openstack service create --name nova \
  --description "OpenStack Compute" compute
    ```
- Create the Compute service API endpoints:

  ```
   openstack endpoint create --region RegionOne \
  compute public http://controller:8774/v2.1/%\(tenant_id\)s
  ```
  
  ```
  openstack endpoint create --region RegionOne \
  compute internal http://controller:8774/v2.1/%\(tenant_id\)s
  ```
  
  ```
  openstack endpoint create --region RegionOne \
  compute admin http://controller:8774/v2.1/%\(tenant_id\)s
  ```
  

**Install & configure**

- Install the packages:

		apt-get install nova-api nova-conductor nova-consoleauth \
  		nova-novncproxy nova-scheduler
- Edit the /etc/nova/nova.conf file and complete the following actions:

  ```
  [DEFAULT]
	enabled_apis = osapi_compute,metadata
	rpc_backend = rabbit
	auth_strategy = keystone
    my_ip = 192.168.0.21
    use_neutron = True
	firewall_driver = nova.virt.firewall.NoopFirewallDriver

	[api_database]
	connection = mysql+pymysql://nova:NOVA_DBPASS@controller/nova_api

	[database]
	connection = mysql+pymysql://nova:NOVA_DBPASS@controller/nova 

	[oslo_messaging_rabbit]
	rabbit_host = controller
	rabbit_userid = openstack
	rabbit_password = RABBIT_PASS 		 
 
 	[keystone_authtoken]
	auth_uri = http://controller:5000
	auth_url = http://controller:35357
	memcached_servers = controller:11211
	auth_type = password
	project_domain_name = default
	user_domain_name = default
	project_name = service
	username = nova
	password = NOVA_PASS    		  	
	
	[vnc]
	vncserver_listen = $my_ip
	vncserver_proxyclient_address = $my_ip
	
	[glance]
    api_servers = http://controller:9292
    
    [oslo_concurrency]
	lock_path = /var/lib/nova/tmp
```
	Replace NOVA_DBPASS with the password you chose for the Compute databases.

	Replace RABBIT_PASS with the password you chose for the openstack account in RabbitMQ.


	Replace NOVA_PASS with the password you chose for the nova user in the Identity service.

- Populate the Compute databases:

		 su -s /bin/sh -c "nova-manage api_db sync" nova
		 su -s /bin/sh -c "nova-manage db sync" nova
- Restart the Compute services:
 
 ```
 service nova-api restart
 service nova-consoleauth restart
 service nova-scheduler restart
 service nova-conductor restart
 service nova-novncproxy restart		 
 ```
 
 ####Compute Node:-
 
- Install the packages:
 	
 		apt-get install nova-compute
- Edit the /etc/nova/nova.conf file and complete the following actions:

  ```
  [DEFAULT]
rpc_backend = rabbit
auth_strategy = keystone
my_ip = 192.168.0.24
use_neutron = True
firewall_driver = nova.virt.firewall.NoopFirewallDriver


	[oslo_messaging_rabbit]
	rabbit_host = controller
	rabbit_userid = openstack
	rabbit_password = RABBIT_PASS
		
	
	[keystone_authtoken]
	auth_uri = http://controller:5000
	auth_url = http://controller:35357
	memcached_servers = controller:11211
	auth_type = password
	project_domain_name = default
	user_domain_name = default
	project_name = service
	username = nova
	password = NOVA_PASS
	
	[vnc]
	enabled = True
	vncserver_listen = 0.0.0.0	
	vncserver_proxyclient_address = $my_ip
	novncproxy_base_url = http://controller:6080/vnc_auto.html
	
	[glance]
    api_servers = http://controller:9292
    
    [oslo_concurrency]
	lock_path = /var/lib/nova/tmp
	
	```
- Determine whether your compute node supports hardware acceleration for virtual machines:

		egrep -c '(vmx|svm)' /proc/cpuinfo
If this command returns a value of one or greater, your compute node supports hardware acceleration which typically requires no additional configuration.

	If this command returns a value of zero, your compute node does not support 	hardware acceleration and you must configure libvirt to use QEMU instead of 	KVM.
		
	- Edit the [libvirt] section in the /etc/nova/nova-compute.conf file as follows:

		
			[libvirt]
			virt_type = qemu
- Restart the Compute service:

		 service nova-compute restart

**Verify Operation**

- Source the admin credentials to gain access to admin-only CLI commands:
 	
 		 . admin-openrc
- List service components to verify successful launch and registration of each process:
 
 		openstack compute service list
 
-------

##Networking Service

-----

OpenStack Networking (neutron) allows you to create and attach interface devices managed by other OpenStack services to networks. 

####Controller Node:-

**Prerequisites** 
 
- To create the database, complete these steps:

  - Use the database access client to connect to the database server as the root user:
   
   		 	mysql -u root -p
  - Create the neutron database:

     	    CREATE DATABASE neutron;
         
   - Grant proper access to the neutron database, replacing NEUTRON_DBPASS with a suitable password:

		```
		GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' \
  		IDENTIFIED BY 'NEUTRON_DBPASS';
		GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' \
  		IDENTIFIED BY 'NEUTRON_DBPASS';
  ```
  Replace 'NEUTRON_DBPASS with your password
  
  - exit database.

- Source the admin credentials to gain access to admin-only CLI commands:

	     . admin-openrc
  
- To create the service credentials, complete these steps:

   - Create the neutron user:
   
   			openstack user create --domain default --password-prompt neutron
   			
   	- Add the admin role to the neutron user:


			openstack role add --project service --user neutron admin

	- Create the neutron service entity:

			openstack service create --name neutron \
		  --description "OpenStack Networking" network
							       		 	
- Create the Networking service API endpoints:

 ```
 openstack endpoint create --region RegionOne \
  network public http://controller:9696
  ```
  
  ```
  openstack endpoint create --region RegionOne \
  network internal http://controller:9696
  ```
  
  ```
  openstack endpoint create --region RegionOne \
  network admin http://controller:9696
  ```
  
**Configure networking options**

You can deploy the Networking service using **one of two architectures** represented by options 1 and 2.

- Networking Option 1: Provider networks
- Networking Option 2: Self-service networks  

####- Networking Option 1: Provider networks
 
 - Install and configure the Networking components
 
 		apt-get install neutron-server neutron-plugin-ml2 \
		neutron-linuxbridge-agent neutron-dhcp-agent \
 	 	neutron-metadata-agent
  
- Edit the /etc/neutron/neutron.conf file and complete the following actions:

 ```
[DEFAULT]
core_plugin = ml2
service_plugins =
rpc_backend = rabbit
auth_strategy = keystone
notify_nova_on_port_status_changes = True
notify_nova_on_port_data_changes = True


 [database]
connection = mysql+pymysql://neutron:NEUTRON_DBPASS@controller/neutron

	[oslo_messaging_rabbit]
rabbit_host = controller
rabbit_userid = openstack
rabbit_password = RABBIT_PASS

	[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = NEUTRON_PASS  
  
 [nova]
auth_url = http://controller:35357
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = nova
password = NOVA_PASS
 ```
 Replace all password with your password
 
- Configure the Modular Layer 2 (ML2) plug-in.Edit the /etc/neutron/plugins/ml2/ml2_conf.ini file and complete the following actions:

	```
[ml2]
type_drivers = flat,vlan   
mechanism_drivers = linuxbridge
extension_drivers = port_security

	[ml2_type_flat]
flat_networks = provider
 				 
	[securitygroup]
enable_ipset = True
```
- Configure the Linux bridge agent.Edit the /etc/neutron/plugins/ml2/linuxbridge_agent.ini file and complete the following actions:

  ```
  [linux_bridge]
physical_interface_mappings = provider:PROVIDER_INTERFACE_NAME

   [vxlan]
enable_vxlan = False
 
   [securitygroup]
enable_security_group = True
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
```

	Replace PROVIDER_INTERFACE_NAME with your interface name

- Configure the DHCP agent.Edit the /etc/neutron/dhcp_agent.ini file and complete the following actions:

  ```
  [DEFAULT]
interface_driver = neutron.agent.linux.interface.BridgeInterfaceDriver
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
enable_isolated_metadata = True
	```
	
####- Networking Option 2: Self-service networks  

- Install and configure the Networking components 

	 ```
	 apt-get install neutron-server neutron-plugin-ml2 \
  neutron-linuxbridge-agent neutron-l3-agent neutron-dhcp-agent \
  neutron-metadata-agent
  
- Configure the server component.Edit the /etc/neutron/neutron.conf file and complete the following actions:

  ```
[DEFAULT]
core_plugin = ml2
service_plugins =
rpc_backend = rabbit
auth_strategy = keystone
notify_nova_on_port_status_changes = True
notify_nova_on_port_data_changes = True


 [database]
connection = mysql+pymysql://neutron:NEUTRON_DBPASS@controller/neutron

	[oslo_messaging_rabbit]
rabbit_host = controller
rabbit_userid = openstack
rabbit_password = RABBIT_PASS

	[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = NEUTRON_PASS  
  
 [nova]
auth_url = http://controller:35357
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = nova
password = NOVA_PASS
   
- Configure the Modular Layer 2 (ML2) plug-in.Edit the /etc/neutron/plugins/ml2/ml2_conf.ini file and complete the following actions:

  ```
  [ml2]
...
type_drivers = flat,vlan,vxlan
tenant_network_types = vxlan
mechanism_drivers = linuxbridge,l2population
extension_drivers = port_security

	[ml2_type_flat]
flat_networks = provider

	[securitygroup]
enable_ipset = True


- Configure the Linux bridge agent.Edit the /etc/neutron/plugins/ml2/linuxbridge_agent.ini file and complete the following actions:

  ```
  [linux_bridge]
physical_interface_mappings = provider:PROVIDER_INTERFACE_NAME

  [vxlan]
enable_vxlan = True
local_ip = OVERLAY_INTERFACE_IP_ADDRESS
l2_population = True

	[securitygroup]
enable_security_group = True
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
  ```

	Replace provider_interface _name with your interface

- Configure the layer-3 agent.Edit the /etc/neutron/l3_agent.ini file and complete the following actions:

	```
	[DEFAULT]
interface_driver = neutron.agent.linux.interface.BridgeInterfaceDriver
external_network_bridge =

- Configure the DHCP agent.Edit the /etc/neutron/dhcp_agent.ini file and complete the following actions:

   ```
   [DEFAULT]
interface_driver = neutron.agent.linux.interface.BridgeInterfaceDriver
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
enable_isolated_metadata = True
  ```
  
**- Once configure any one network interface start from here**
  
- Configure the metadata agent.Edit the /etc/neutron/metadata_agent.ini file and complete the following actions:

	```
	[DEFAULT]
	nova_metadata_ip = controller
	metadata_proxy_shared_secret = METADATA_SECRET 
	
- Configure Compute to use Networking,Edit the /etc/nova/nova.conf file and perform the following actions:

  ```
  [neutron]
url = http://controller:9696
auth_url = http://controller:35357
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = NEUTRON_PASS

	service_metadata_proxy = True
	metadata_proxy_shared_secret = METADATA_SECRET
 ```
 Replace NEUTRON_PASS with the password you chose for the neutron user in the Identity service.

	Replace METADATA_SECRET with the secret you chose for the metadata proxy.

- Populate the database:

  ```
    # su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
  ```
- Restart the Compute API service:
 		
 		 service nova-api restart
- Restart the Networking services.

  For both networking options:
  
  		service neutron-server restart
		service neutron-linuxbridge-agent restart
		service neutron-dhcp-agent restart
		service neutron-metadata-agent restart
		
- For networking option 2, also restart the layer-3 service:

		service neutron-l3-agent restart		   
####Compute Node:- 
- Install packages

 		apt-get install neutron-linuxbridge-agent
 		
- Edit the /etc/neutron/neutron.conf file and complete the following actions:

  ```
     [DEFAULT]
rpc_backend = rabbit
auth_strategy = keystone

	[oslo_messaging_rabbit]
rabbit_host = controller
rabbit_userid = openstack
rabbit_password = RABBIT_PASS

	[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = NEUTRON_PASS
	```
 Replace all password with your password

**Configure networking options**
 
Choose Networking options as per you configure on controller node
 
####-Networking Option 1: Provider networks:-

- Configure the Linux bridge agent,Edit the /etc/neutron/plugins/ml2/linuxbridge_agent.ini file and complete the following actions:

   ```
   [linux_bridge]
physical_interface_mappings = provider:PROVIDER_INTERFACE_NAME

	[vxlan]
enable_vxlan = False

	[securitygroup]
enable_security_group = True
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver 

 ```
 Replace Provide_interface_name with your interface name
 
####-Networking Option 2: Self-service networks

- Configure the Linux bridge agent,Edit the /etc/neutron/plugins/ml2/linuxbridge_agent.ini file and complete the following actions:

   ```
   [linux_bridge]
physical_interface_mappings = provider:PROVIDER_INTERFACE_NAME

	[vxlan]
enable_vxlan = True
local_ip = OVERLAY_INTERFACE_IP_ADDRESS
l2_population = True

	[securitygroup]
enable_security_group = True
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver	
  	```
  	Replace Provide_interface_name with your interface name
  	
 **Once any one network configure on compute return here** 	
- Configure Compute to use Networking.Edit the /etc/nova/nova.conf file and complete the following actions:

    ```
    [neutron]
url = http://controller:9696
auth_url = http://controller:35357
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = NEUTRON_PASS 

   ```
   Replace NEUTRON_PASS with the password you chose for the neutron user in the Identity service.

- Restart the Compute service:

		service nova-compute restart
- Restart the Linux bridge agent:
 		
 		service neutron-linuxbridge-agent restart
 					
**Verify Operation**

- Source the admin credentials to gain access to admin-only CLI commands:

    	. admin-openrc
- List loaded extensions to verify successful launch of the neutron-server process:

		neutron ext-list
    	
- networking verification:-
	
		neutron agent-list			
		
------

##Dashboard

------

- Install packages:-

		apt-get install openstack-dashboard
- Edit the /etc/openstack-dashboard/local_settings.py file and complete the following actions:

	```
	OPENSTACK_HOST = "controller"
	
	ALLOWED_HOSTS = ['*', ]
	
	SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
	CACHES = {
    'default': {
         'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
         'LOCATION': 'controller:11211',
    }
}						

   OPENSTACK_KEYSTONE_URL = "http://%s:5000/v3" % OPENSTACK_HOST
   
   OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True
   
   OPENSTACK_API_VERSIONS = {
    "identity": 3,
    "image": 2,
    "volume": 2,
}

  OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = "default"
  
  OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"
  
  OPENSTACK_NEUTRON_NETWORK = {
    'enable_router': False,
    'enable_quotas': False,
    'enable_distributed_router': False,
    'enable_ha_router': False,
    'enable_lb': False,
    'enable_firewall': False,
    'enable_vpn': False,
    'enable_fip_topology_check': False,
}
 
  TIME_ZONE = "TIME_ZONE"
  ```
- Reload the web server configuration:

		service apache2 reload

**Verify Operation**
		
- Access the dashboard using a web browser at http://controller/horizon.

 Authenticate using admin or demo user and default domain credentials.		  

-----

##Block Storage service
------
The Block Storage service (cinder) provides block storage devices to guest instances. The method in which the storage is provisioned and consumed is determined by the Block Storage driver, or drivers in the case of a multi-backend configuration. 

####Controller Node:-

**Prerequisites**

- To create the databases, complete these steps:
   - Use the database access client to connect to the database server as the root user:
    				
    		mysql -u root -p
   - Create the nova_api and nova databases:

			CREATE DATABASE cinder;
 		
   - Grant proper access to the databases:

   			GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' \
  			IDENTIFIED BY 'CINDER_DBPASS';
			
			GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' \
  			IDENTIFIED BY 'CINDER_DBPASS';
	Replace cinder_pass with your password.
	
- Source the admin credentials to gain access to admin-only CLI commands:

    	. admin-openrc		  

- To create the service credentials, complete these steps:

   - Create a cinder user:

	  		openstack user create --domain default --password-prompt cinder    	
	- Add the admin role to the cinder user:

           openstack role add --project service --user cinder admin

   - Create the cinder and cinderv2 service entities:

        ```
       openstack service create --name cinder \
	--description "OpenStack Block Storage" volume 
			 
		```
	 	
	 		openstack service create --name cinderv2 \
 			--description "OpenStack Block Storage" volumev2

- Create the Block Storage service API endpoints: 
 
 	```
 	openstack endpoint create --region RegionOne \
  volume public http://controller:8776/v1/%\(tenant_id\)s
  
  	```
  	
  	```
  	openstack endpoint create --region RegionOne \
  volume internal http://controller:8776/v1/%\(tenant_id\)s
   ```
   
   ```
   openstack endpoint create --region RegionOne \
  volume admin http://controller:8776/v1/%\(tenant_id\)s
  ```
  
  ```
  openstack endpoint create --region RegionOne \
  volumev2 public http://controller:8776/v2/%\(tenant_id\)s
  ```
  
  ```
  openstack endpoint create --region RegionOne \
  volumev2 internal http://controller:8776/v2/%\(tenant_id\)s
  ```
  
  ```
  openstack endpoint create --region RegionOne \
  volumev2 admin http://controller:8776/v2/%\(tenant_id\)s
  ```
 
**Install & configure components**  

- Install the packages:

		apt-get install cinder-api cinder-scheduler
	
- Edit the /etc/cinder/cinder.conf file and complete the following actions:


   ```
   [DEFAULT]
rpc_backend = rabbit
auth_strategy = keystone
my_ip = 192.168.0.21

	[database]
connection = mysql+pymysql://cinder:CINDER_DBPASS@controller/cinder
	
	[oslo_messaging_rabbit]
rabbit_host = controller
rabbit_userid = openstack
rabbit_password = RABBIT_PASS

	[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = cinder
password = CINDER_PASS				

	[oslo_concurrency]
lock_path = /var/lib/cinder/tmp
```
Replace all password with your password

- Configure Compute to use Block Storage,Configure Compute to use Block Storage

		[cinder]
		os_region_name = RegionOne
- Restart the Compute API service:

		 service nova-api restart
- Restart the Block Storage services:

		 service cinder-scheduler restart
		 service cinder-api restart		 
		 
####Compute or Storage Node:-


**Prerequisites**		

- Install the supporting utility packages:
 		
 		apt-get install lvm2
- Create the LVM physical volume /dev/sdb:

		pvcreate /dev/sdb
		
- Create the LVM volume group cinder-volumes:


		vgcreate cinder-volumes /dev/sdb
		
- Edit the /etc/lvm/lvm.conf file and complete the following actions:

  			devices {
			filter = [ "a/sdb/", "r/.*/"]						 		
- Install the packages:

		apt-get install cinder-volume
- Edit the /etc/cinder/cinder.conf file and complete the following actions:

    ```
    [DEFAULT]
rpc_backend = rabbit
auth_strategy = keystone
my_ip = 
enabled_backends = lvm
glance_api_servers = http://controller:9292

	[database]
connection = mysql+pymysql://cinder:CINDER_DBPASS@controller/cinder

	[oslo_messaging_rabbit]
rabbit_host = controller
rabbit_userid = openstack
rabbit_password = RABBIT_PASS

	[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = cinder
password = CINDER_PASS

	[lvm]
volume_driver = cinder.volume.drivers.lvm.LVMVolumeDriver
volume_group = cinder-volumes
iscsi_protocol = iscsi
iscsi_helper = tgtadm
					
	[oslo_concurrency]
lock_path = /var/lib/cinder/tmp		
```
Replace all password with your password

- Restart the Block Storage volume service including its dependencies:

		service tgt restart
		service cinder-volume restart		
		
**Verify Operation**	

- Source the admin credentials to gain access to admin-only CLI commands:

		. admin-openrc		
- List service components to verify successful launch of each process:


		cinder service-list		
		
------
		