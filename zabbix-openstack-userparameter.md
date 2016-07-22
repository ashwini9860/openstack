#Zabbix to minitor openstack:

###Using User Parameter


**Zabbix - Setting Up a New User Parameter**

- To set up a new monitoring parameter, open /etc/zabbix/zabbix_agentd.conf.

- Add a line at the bottom of the page:

		UserParameter=new.parameter,full path to script
 ex.
    
	    UserParameter=nova-check,/etc/zabbix/external_scripts/nova-check.sh
 

-  The script must be under the zabbix user and group. Use 
		
		chown zabbix scriptname
		chgrp zabbix scriptname

- Restart zabbix_agent using the following command:

		service zabbix_agent restart

- To test whether if the new.parameter is working from agentd,

		zabbix_agentd -t new.parameter
Note that zabbix_agentd is executed using the current user.

- Finally, we have to test whether if the server can retrieve the value from agentd.

		zabbix_get -s localhost -p 10050 -k newparameter
		
- Configure an Item on the Zabbix server like this :

		Name : nova-check
		Type : Zabbix Agent
  		key : nova-check
	    Host interface : 192.168.0.21:10050
	    Type of Information : Numeric
	    Application : Zabbix Agent
	    Enabled : check yes
	   
	 Fill the apropriate info as per your environment  other are default & save it, this will create custom monitoring for your zabbix agent    	