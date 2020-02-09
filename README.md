# Tekkion Assignment
### This repo contains script which would deploy docker environment on AWS, deploys spring music java application (https://github.com/cloudfoundry-samples/spring-music) in docker swarm environment, and deploys prometheus to monitor containers as well as nodes. 
### Another folder kube_tek deploys kubernetes on aws using kops. 

### Spring Music app setup on AWS.
### prerequisite ( git, aws cli, terraform )
1. git clone https://github.com/karthikr87/tekion_assignment.git
### EC2 instance will need ssh keys during deployment. To generate
2. ssh-keygen ( generate withour passphrase )
3. enable agent forwarding "ssh-add -i ~/.ssh/you_key_name" this step requires to connect instance in private subnet via jumpbox
### To add the key location in terraform script
4. cd three_tier_web/
5. open jumpbox.tf in any editor
6. Under resource aws_key_pair you will find "public_key=file("~/.ssh/ssh_tekk.pub")" instead of ssh_tekk.pub put your key name
### All set. 
7. Inside three_tier_web/ 
   1. execute "terraform init"
   2. terraform plan (ouputs the details about the resource creation)
   3. terraform apply (creates all resources on AWS)
### End of the script, terraform outputs public ip of jumpbox and load balancer name. Please note down these.
bastion_public_ip = ##.###.###.130 (public_ip)
espm_web_lb_dns_name = "####################.elb.amazonaws.com (load_balancer_name)

### Our environment is ready. Now we need to deploy spring music app using Ansible. To do that
8. cd ../Ansible-swarm/

### Ansible needs to know on which hosts it needs to perform action. So lets get the ip address of EC2 instances.
9. Inside the Ansible-swarm folder you will find get_ip_address.sh. Execute it.
   1. ./get_ip_address.sh ( this will get the ip adddresses and write it into a file called hosts in the same folder.
   2. hosts will contain 3 ip addresses. Coz we have launched on 3 instances for our setup.
   3. we need choose one ip address as masters and other two as workers. So edit the hosts file as shown below.
      [masters]
      10.0.3.167
      [workers]
      10.0.4.48
      10.0.3.17
   4. ansible will use this file as input and will create docker swarm env on these intances. 

### We hosted all instances in private subnet. So you can access it only via jumpbox, and also we need to move /Ansible-swarm folder inside jumpbox
10. scp -rp ../Ansible-swarm ubuntu@<public_ip>:~

### jumpbox comes with docker and ansible cli. So no need to deploy any of it.
11. ssh -A ubuntu@<public_ip>
12. cd /Ansible-swarm 
13. ansible-playbook docker-swarm.yml ( to init docker swarm env )
14. ansible-playbook docker-stack.yml ( to deploy java app in swarm env )
15. ansible-playbook docker-monitor.yml ( to deploy prometheus on swarm env )

### Complete environment is ready. 
16. To access the app paste the load balancer name in the browser. spring-music app will be loaded. 
17. To access the monitoring dashboard http://public-ip:3000 
    1. user name - admin
    2. password - admin
    3. Go to settings add datasource as prometheus. 
       In the url section add http://master-node-ip:9090 ( From the hosts file get the master ip )
### End of first assignment

## Second Assignment
### prerequisite ( aws cli, kops, kubectl, jq )
### Deploy kubernetes using kops
1. cd ../kube_tek/
2. ./deploy_k8s_kops.sh  ( deploys cluster in ap-souht-1 environment )
3. ./k8s_dashboard.sh ( deploys dashboard, creates admin user, and prints token to access the dashboard using admin user)
4. To access the dashboard - http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
5. Enter the token and the welcome page will be loaded.
