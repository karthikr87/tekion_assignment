# tekion_assignment
This repo contains script to setup highly available docker env on AWS.

# Setup aws env
1. git clone this repo
2. cd three_tier_web/
3. generate new ssh key to connect to the instance
4. To add the key edit the line public_key = file("~/.ssh/<your key name>") in jumpbox.tf
5. Terraform plan
6. Terraform apply
