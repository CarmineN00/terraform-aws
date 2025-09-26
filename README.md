# terraform-aws

A simple IaaC lab to explore aws, in particular network services:
- Virtual Private Cloud (VPC)
- VPC Peering
- VPC Security Group
- VPC Internet Gateway (IGW)
- Amazon Machine Image (AMI)
- EC2 instace

and the fundamental concepts of terraform:

- terraform/provider/data/resource block
- variables, outputs, modules

## Prerequisites
- The Terraform CLI (1.2.0+) installed.
- The AWS CLI installed.
- An AWS account and associated credentials that allow you to create resources

## Info

Before starting using terraform, as mentioned above, you need an access key that you can generate in the IAM section.<br />
To use your IAM credentials to authenticate the Terraform AWS provider you could use **aws configure** command.<br />
Given that, you can create the topology shown below, with **terraform init** -> **terraform validate** -> **terraform apply** commands.<br />
Even though the ec2 istances used are free tier/very cheap, you should not forget to execute **terraform destroy** when you're done.

## Architecture

![tf-aws-lab](/images/tf-aws-arch.png)
