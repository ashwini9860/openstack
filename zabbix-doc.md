#Install zabbix server on ubuntu 14.04

- add zabbix package in source file

		sudo nano /etc/apt/sources.list

	Add the following items at the end of the file:

		# Zabbix Application PPA
		deb http://ppa.launchpad.net/tbfr/zabbix/ubuntu precise main
		deb-src http://ppa.launchpad.net/tbfr/zabbix/ubuntu precise main
- Add the PPA's key so that apt-get trusts the source:

		sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C407E17D5F76A32B

- Set the server it's hostname

		echo "zabbix.mydomain.com" > /etc/hostname
		hostname -F /etc/hostname

- Update /etc/hosts

		127.0.0.1 localhost.localdomain localhost
		192.168.0.21 zabbix-server

- Update and install Zabbix server and required packages.
	
		sudo apt-get update
		sudo apt-get install zabbix-server-mysql php5-mysql zabbix-frontend-php
		
	Note down the root password you have chosen, you'll need it later. 

- Next edit the Zabbix configuration.

		sudo nano /etc/zabbix/zabbix_server.conf

 Adjust the following values and make a note of the password you've chosen. You'll need it later too.

		DBName=zabbix
		DBUser=zabbix
		DBPassword=your_chosen_password_here


- Unzip the mysql data for importing them into the database you'll create in the next step.

		cd /usr/share/zabbix-server-mysql/
		sudo gunzip *.gz

- Login to MySql using the root password.

		mysql -u root -p

- Create a user for Zabbix (and a database) that matches the information we entered in the "/etc/zabbix/zabbix_server.conf" file.

		create user 'zabbix'@'localhost' identified by 'your_chosen_password_here';	
		create database zabbix;
		grant all privileges on zabbix.* to 'zabbix'@'localhost'; 
		flush privileges;
		exit;

-	Next we'll import the schemas into the newly created database.

		mysql -u zabbix -p zabbix < schema.sql
		mysql -u zabbix -p zabbix < images.sql
		mysql -u zabbix -p zabbix < data.sql

- Edit a few PHP settings by modifying the php.ini file.

		sudo nano /etc/php5/apache2/php.ini

Search and adjust the following data. (Or add them if they can't be found.)

		post_max_size = 16M
		max_execution_time = 300
		max_input_time = 300
		date.timezone = "UTC"

- Next copy the example config to the /etc/zabbix directory. Then make the necessary adjustments too.

		sudo cp /usr/share/doc/zabbix-frontend-php/examples/zabbix.conf.php.example /etc/zabbix/zabbix.conf.php
		sudo nano /etc/zabbix/zabbix.conf.php
		
	```
		$DB['DATABASE'] = 'zabbix';
		$DB['USER'] = 'zabbix';	
		$DB['PASSWORD'] = 'your_chosen_password_here'
	```	

- Then copy the example apache config to the /etc/apache2/conf-available/ directory to make Zabbix and Apache work together.

		sudo cp /usr/share/doc/zabbix-frontend-php/examples/apache.conf /etc/apache2/conf-available/zabbix.conf

	```
sudo a2enconf zabbix.conf
	```

  ```
sudo a2enmod alias
	```
  	```
sudo service apache2 restart
 	```
- Then edit the below file & start property yes
  
		sudo nano /etc/default/zabbix-server
 
	Go to the bottom and adjust the "START" property to read "yes":

		START=yes

- And start the Zabbix server.

		sudo service zabbix-server start

	If you would like to have zabbix running on the root of the domain instead of /zabbix execute the following;

		sudo nano /etc/apache2/sites-available/000-default.conf

- And set the "DocumentRoot" like this;

		DocumentRoot /usr/share/zabbix
Then restart Apache.

##Installing Zabbix agent(s) on server machines.

- update system & install zabbix agent
		
		sudo apt-get update
		sudo apt-get install zabbix-agent

- edit zabbix configuration file

		sudo nano /etc/zabbix/zabbix_agentd.conf

	Look for: Server=localhost (or Server=127.0.0.1) and change 'localhost' with the IP address of your Zabbix install.

- Save and close the file and restart the agent software:

		sudo service zabbix-agent restart

- In your web browser, navigate to your Zabbix server's IP address followed by "/zabbix": http://xx.xx.xx.xx/zabbix

- Use the following default credentials to login.

	Username = admin
	
	Password = zabbix

- When you have logged in, click on the "Configuration" button, and then "Hosts" in the top navigation bar.

- Click on the name of the server (by default, this should be "Zabbix server"). This will open the host configuration page. Adjust the Hostname to reflect the hostname of your Zabbix server (this should be the same hostname you entered in the agent configuration for the server machine). At the bottom, change the "Status" property to "Monitored". Click save.

- You will be dopped back to the Hosts configuration page. Re-click on the hostname again. This time, click on the "Clone" button at the bottom of the page. We will configure this to reflect the settings of the client machine. Change the hostname and the IP address to reflect the correct information from the client agent file.

- In the "groups" section, select "Zabbix servers" and click the right arrow icon to remove that group. Select the "Linux servers" and click the left arrow icon to add that group setting.

- Click "Save" at the bottom. After a few minutes, you should be able to see both computers by going to "Monitoring" and then clicking on "Latest data"
 There should be information for both the server and client machines populating.

- If you click on the arrows next to an item, you can see the collected information. If you click "Graph" you will see a graphical representation of the data points that have been collecteInstalling Zabbix on Ubuntu 14.04
