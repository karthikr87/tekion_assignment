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
