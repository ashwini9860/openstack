#Openstack installation ubuntu 14.04 using mitaka:-

The OpenStack project is an open source cloud computing platform that supports all types of cloud environments. The project aims for simple implementation, massive scalability, and a rich set of features.

##Hardware requirements:-

![](Downloads/hard-openstack.png)


The following minimum requirements should support a proof-of-concept environment with core services:-

- Controller Node: 1 processor, 4 GB memory, and 5 GB storage
- Compute Node: 1 processor, 2 GB memory, and 10 GB storage

##Network layout:-

![](Downloads/networkl-openstack.png)

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

###Identity service:-
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
###Image service
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
 
 		openstack image list
 
 -----				 
  		