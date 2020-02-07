# tekion_assignment
This repo contains script to setup highly available docker env on AWS.
# First assignment
# Setup aws env
1. git clone this repo
2. cd three_tier_web/
3. generate new ssh key to connect to the instance
4. To add the key edit the line in jumpbox.tf "public_key = file("~/.ssh/your key name") "
5. Terraform plan
6. Terraform apply
This will output public ip of jumpbox (to ssh) and dns name of elb (to access the java app ). Please note down these. 

# connect to jumpbox to deploy java app using ansible
1. cd ../Ansible-swarm/
2. run ./get_ip_address.sh to get ip's of instances and store in hosts file.
   we will be deploying spring music app in these instances. 
3. Transfer ansible code to jumpbox using scp -rp ../Ansible-swarm ubuntu@<public_ip>:~
4. ssh -A ubuntu@public_ip
5. inside the jumpbox cd Ansible-swarm
6. To create docker swarm execute - ansible-playbook docker-swarm.yml
   This will create docker swarm and add worker nodes also
7. Final step to deploy app - ansible-playbook docker-stack.yml
   This will deploy java app with postgres db. Web server will be running with 3 replicas where db with 1 replica.
8. use the dns name to access the app. 

# Second assignment
1. cd kube_tek
2. ./deploy_k8s_kops.sh to setup cluster using kops on aws env. This will deploy the cluster in ap-south-1 region. This will take 10 to 15 minutes to spin up the cluster. 
3. ./k8s_dashboard.sh to deploy dashboard for the cluster. This will create admin user and prints token to log in to dashabord. 
4. This folder has yml file to deploy nginx app and create load balancer type service.
