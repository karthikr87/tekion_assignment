#!/bin/bash

# This script will deploy k8s cluster using kops on AWS
# It will create neccessary resources (s3 bucket, IAM user..) for k8s cluster

echo "Checking Prerequisites on mac... "
AWSCMD=`which aws`
if [[ -z "$AWSCMD" ]]; then
  echo "Cannot find aws cli. Installing the latest version using pip"
  #`python3 -m pip install awscli`
  exit 1
fi

KUBECTL=`which kubectl`
if [[ -z "$KUBECTL" ]]; then
  echo "Cannot find kubectl. Installing the latest version using brew"
  #`brew install kubectl`
  exit 1
fi
JQCMD=`which jq`
if [[ -z "$JQCMD" ]]; then
  echo "Cannot find jq. Installing the latest version using brew"
  #`brew install jq`
  exit 1
fi
KOPSCMD=`which kops`
if [[ -z "$KOPSCMD" ]]; then
  echo "Cannot find kops. Installing the latest version using brew"
  #`brew install kops`
  exit 1
fi
echo "Prerequisites check is done. Proceed to create cluster"
declare -a POLICYNAMES
export REGION=ap-south-1
export ZONE=ap-south-1a
POLICYNAMES=("AmazonEC2FullAccess" "AmazonRoute53FullAccess" "AmazonS3FullAccess" "IAMFullAccess" "AmazonVPCFullAccess")
# create IAM user and group
aws iam list-groups | grep kops
if [[ $? -eq 0 ]];
then
  echo "kops group already exists"
else
  echo "kops group does not exists. Creating one"
  aws iam create-group --group-name kops
  for policy in "${POLICYNAMES[@]}"; do
    echo "adding policy to group"
    echo $policy
    aws iam attach-group-policy --policy-arn "arn:aws:iam::aws:policy/$policy" --group-name kops
  done
  aws iam create-user --user-name kops
  aws iam add-user-to-group --user-name kops --group-name kops
  aws iam create-access-key --user-name kops > accessKey.json
  export AWS_ACCESS_KEY_ID=$(cat accessKey.json | jq '.AccessKey.AccessKeyId' | tr -d '"')
  export AWS_SECRET_ACCESS_KEY=$(cat accessKey.json | jq '.AccessKey.SecretAccessKey' | tr -d '"')
  echo $AWS_ACCESS_KEY_ID
  echo $AWS_SECRET_ACCESS_KEY
  aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
  aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
fi

echo "waiting for 30 seconds for user creation"
sleep 30s
# create bucket for k8s cluster to store the state of cluster
export KOPS_BUCKET_NAME=kops-aws-state-store
aws s3 ls | grep $KOPS_BUCKET_NAME
if [[ $? -eq 0 ]]; then
  echo "bucket already exists"
else
  echo "bucket not exists. creating the new one"
  aws s3api create-bucket --bucket $KOPS_BUCKET_NAME --region $REGION --create-bucket-configuration LocationConstraint=$REGION
  aws s3api put-bucket-versioning --bucket $KOPS_BUCKET_NAME --versioning-configuration Status=Enabled
  aws s3api put-bucket-encryption --bucket $KOPS_BUCKET_NAME --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
fi

echo "creating cluster using kops"
export NAME=kopscluster.k8s.local
export KOPS_STATE_STORE=s3://$KOPS_BUCKET_NAME
kops create cluster --zones $ZONE --master-count 1 --node-count 2 --name $NAME --yes
