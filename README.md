# Kubernetes Project Learning


## AWS instructions
https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html


### Template ==> create VPC https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2018-08-30/amazon-eks-vpc-sample.yaml

========================================
### This bash shell script will create the necessaries AWS resources for Kubernetes start up infrastructure, this is the automated script with all aws instructions.
#### Follow the instructions

* (1)- Just clone this github repo

```
git clone https://github.com/Calliari/aws-kubernetes.git && cd aws-kubernetes
```
* (2)- Make the script excitable  and run it

```
chmod +x automate_eks_env.sh && ./automate_eks_env.sh
```

* (3)- create the Kubernetes with `aws eks` CLI cmd cluster and replace the *subnets ids* as well as the *security group ids*
*this may take some time* be patient...

```
aws eks create-cluster --name devel --role-arn arn:aws:iam::571428570978:role/eksServiceRole --resources-vpc-config subnetIds=subnet-0c..,subnet-0cc...,subnet-0c0...,securityGroupIds=sg-00a...
```
