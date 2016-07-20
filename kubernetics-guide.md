##Kubernetics

Kubernetes is a powerful system, developed by Google, for managing containerized applications in a clustered environment. It aims to provide better ways of managing related, distributed components across varied infrastructure

###Kubernetics setup master & minion(ubuntu 14.04):-
 
 -  switch to root user
 - Install pre-requisite software packages both for master & minion:-
    	
    	- apt-get update  
    	- apt-get install ssh
    	- apt-get install docker.io(using dpkg package)
    	- apt-get install curl
  
 - For Password less login use ssh key base login setup:-
      
     
   		 - ssh-keygen -t rsa
      - copy public key to minions & self 
      - try to login without password 
      
 - Download kubernetics release bundle from official git repository (this for ubuntu only):-
 
 		- wget https://github.com/GoogleCloudPlatform/kubernetes/releases/download/v1.0.1/kubernetes.tar.gz
   
 - Untar Kubernetes bundle in the same directory:-
 
    	- tar -xvf kubernetes.tar.gz
 - To build binaries for kubernetics cluster 
   
     - move inside kubernetes/cluster/ubuntu directory
    			
    		- cd kubernetes/cluster/ubuntu
     - run following script:- 		
     	
     		- ./build.sh 
 - Add this binaries to your path 
 
     - In /etc/environment or ~/.bashrc or ~/.profile
     
 - Configure cluster information by editing kubernetes/cluster/ubuntu/config-default.sh file:-
  
   		 - vim /kubernetes/cluster/ubuntu/config-default.sh
  
   	- make changes in following fields:-
  
  			- export nodes="root@192.168.0.169 root@192.168.0.170"
  			- export roles="ai i"
			- export NUM_MINIONS=${NUM_MINIONS:-2}
			- export FLANNEL_NET=172.16.0.0/16

   
    - **Note:- at roles script has bug so for multiple node setup "ai" "i"**

    - "a" stand for master & "i" stand for minion/node
    
 - Start cluster 
    
     	- cd kubernetes/cluster
		- KUBERNETES_PROVIDER=ubuntu ./kube-up.sh       			
- verify kubernetics cluster get started using:-
   
   		- kubectl get nodes 

- kubernetics commands:-
 
   - to create container using docker images used  
   	
			- kubectl run wordpress --image=tutum/wordpress --port=80 --hostport=81
   
   - to see containers running:-
   
   			- kubectl get pods 			
   - same be listed using docker with command:-
   		
   			- docker ps
   	- to create container using yml file:-
   	
   			- kubectl create -f example.yaml
   	- create a container with replication:-
   	
   			- kubectl run wordpress --image=tutum/wordpress --replicas=2 --port=80 --hostport=81

   - to see replica in pods:-
   
   			- kubectl get rc 

   - create load balance for container:-
   
   			- kubectl run wordpress --image=tutum/wordpress --port=80 --hostport=81 --create-external-load-balancer 
   
   - Scaling replication up:-
   
   			- kubectl scale --current-replicas=2 --replicas=3 eplication controllers wordpress
   			
   - delete replication:-
   
   			- kubectl delete rc NAME 		
- delete cluster using:-
  
 		 - KUBERNETES_PROVIDER=ubuntu ./kube-down.sh 	
   
### Troubleshooting:-
  - make sure all pre-requisite software are their starting at start up before running cluster up script
  - make sure kube- apiserver,proxy,scheduler,controller-manager are running on both master & minion after running start up scripts
  - check docker able to run containers if pods are showing some error if all above services are running without giving any error
  - check log files inside **/var/log/upstart/**
  	