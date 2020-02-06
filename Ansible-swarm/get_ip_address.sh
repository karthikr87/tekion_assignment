#!/bin/bash
echo "Checking Prerequisites on mac... "
AWSCMD=`which aws`
if [[ -z "$AWSCMD" ]]; then
  echo "Cannot find aws cli. Installing the latest version using pip"
  #`python3 -m pip install awscli`
  exit 1
fi
echo "get the list of instance's id from autoscaling group"
for instanceid in $(aws autoscaling describe-auto-scaling-instances --query 'AutoScalingInstances[].InstanceId' --output text)
do
  echo "Getting private ip address and writing it to hosts file"
  aws ec2 describe-instances --instance-id $instanceid  --query 'Reservations[].Instances[].PrivateIpAddress' --output text >> hosts
done
