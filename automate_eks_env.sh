#!/bin/bash

##
 #
 # Author: Caliari
 # Date: 27-Oct-2018
 # kubernet infrastructure
 #
 ##


echo -e "create a stack with cloudformation...\n"
aws cloudformation create-stack --stack-name eks-env --template-url --region eu-west-1 https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2018-08-30/amazon-eks-vpc-sample.yaml --profile default

STACK_CREATED=$(aws cloudformation describe-stacks --stack-name eks-env --region eu-west-1 | grep StackName | cut -d '"' -f 4)
# while $STACK_CREATED == "null" sleep 5
while [ ! "$STACK_CREATED" == "eks-env" ]; do
  echo -e "still create cloudformation stak...\n"
  STACK_CREATED=$(aws cloudformation describe-stacks --stack-name eks-env | grep StackName | cut -d '"' -f 4)
  sleep 5;
done


ROLE_EXIST=$(aws iam get-role --role-name eksServiceRole | grep RoleName | cut -d '"' -f 4)
while [ ! "$ROLE_EXIST" == "eksServiceRole" ]; do
  echo -e "==> role eksServiceRole cannot be found! \n"
  echo -e "creating eksServiceRole role...\n"
  # aws iam create-role --role-name eksServiceRole --assume-role-policy-document file://eksServiceRole-Policy.json;
  aws iam create-role --role-name eksServiceRole --assume-role-policy-document '{"Version": "2012-10-17","Statement": {"Effect": "Allow","Principal": {"Service": "eks.amazonaws.com"},"Action": "sts:AssumeRole"}}' > /dev/null 2>&1
  aws iam attach-role-policy --role-name eksServiceRole --policy-arn arn:aws:iam::aws:policy/AmazonEKSServicePolicy;
  aws iam attach-role-policy --role-name eksServiceRole --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy;
  ROLE_EXIST=$(aws iam get-role --role-name eksServiceRole | grep RoleName | cut -d '"' -f 4)
  sleep 5;
done

echo -e "role for eks name=eksServiceRole already exist...\n"

STACK_STATUS=$(aws cloudformation describe-stacks --stack-name eks-env --region eu-west-1 | grep StackStatus | cut -d '"' -f 4)
while [ "$STACK_STATUS" == "CREATE_IN_PROGRESS" ]; do
  echo -e "still create stack...\n"
  STACK_STATUS=$(aws cloudformation describe-stacks --stack-name eks-env --region eu-west-1 | grep StackStatus | cut -d '"' -f 4)
  sleep 5;
done

# ========================================
echo -e "creating a eks cluster...\n"
# To describe your VPCs and get what we need "vpc-id" created early and cut the first 3 part with the delimter '"'
VPC_ID=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=eks-env-VPC --region eu-west-1 | grep VpcId | cut -d '"' -f 4)

# To describe your subnets and extract what we need (the 3 subnets id)
SUBNETS_ID=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --region eu-west-1 | grep SubnetId | sed s/'"SubnetId": "'/''/ | sed s/'",'/' '/)
SBNTs_ID=$(echo $SUBNETS_ID | sed s/' '/','/g)

EKS_SG_ID=$(aws ec2 describe-security-groups --filters Name=tag:aws:cloudformation:stack-name,Values=eks-env --region eu-west-1 | grep GroupId | cut -d '"' -f 4)

ROLE_ARN=$(aws iam get-role --role-name eksServiceRole --region eu-west-1 | grep Arn | cut -d '"' -f 4)

aws eks create-cluster --name devel --role-arn "$ROLE_ARN" --resources-vpc-config subnetIds="$SBNTs_ID",securityGroupIds="$EKS_SG_ID" --region eu-west-1
# ========================================



EKS_STATUS=$(aws eks describe-cluster --name devel --region eu-west-1 | grep status | cut -d '"' -f 4)
while [ "$EKS_STATUS" == "ACTIVE" ]; do
  echo -e "still create eks cluster...\n"
  EKS_STATUS=$(aws eks describe-cluster --name devel --region eu-west-1 | grep status | cut -d '"' -f 4)
  sleep 10;
done

echo "kubectl need to be intalled"
echo -e "FOR MAC GO TO ==> https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-with-homebrew-on-macos for info! \n"

echo -e "Install aws-iam-authenticator for Amazon EKS \n"
echo -e "instuction ==> https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html \n"

# this will create a file on ~/.kube/config with certs
echo -e "run $ aws eks update-kubeconfig --name devel --region eu-west-1"

SBNTS_ID=$(echo $SBNTs_ID | sed s/','/'\\\\,'/g)

aws cloudformation create-stack --stack-name devel-worker-nodes --template-url --region eu-west-1 https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2018-08-30/amazon-eks-nodegroup.yaml --profile default --parameters ParameterKey=ClusterName,ParameterValue=devel ParameterKey=KeyName,ParameterValue=ireland_pem_key ParameterKey=NodeImageId,ParameterValue=ami-0c7a4976cb6fafd3a ParameterKey=NodeGroupName,ParameterValue=devel-node-group ParameterKey=NodeGroupName,ParameterValue=devel-node-group ParameterKey=VpcId,ParameterValue="$VPC_ID" ParameterKey=ClusterControlPlaneSecurityGroup,ParameterValue="$EKS_SG_ID" ParameterKey=Subnets,ParameterValue="$SBNTS_ID" --capabilities CAPABILITY_IAM

echo "done!"
