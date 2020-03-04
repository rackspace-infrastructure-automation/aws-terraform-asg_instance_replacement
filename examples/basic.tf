terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  version = "~> 2.7"
  region  = "us-west-2"
}

provider "random" {
  version = "~> 2.0"
}

resource "random_string" "rstring" {
  length      = 16
  min_lower   = 1
  min_numeric = 1
  min_upper   = 1
  special     = false
}

module "instance_replacement_simple" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-asg_instance_replacement//?ref=v0.12.0"
}

module "vpc" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-vpc_basenetwork//?ref=v0.12.1"

  name = "my_basic_vpc"
}

module "security_groups" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-security_group//?ref=v0.12.0"

  name   = "my_basic_sg"
  vpc_id = module.vpc.vpc_id
}

module "asg_with_rolling_updates" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-ec2_asg//?ref=v0.12.1"

  ec2_os                   = "amazon2"
  install_codedeploy_agent = true
  instance_type            = "t2.micro"
  name                     = "rolling_updates_enabled"
  security_groups          = [module.security_groups.private_web_security_group_id]
  scaling_max              = 2
  scaling_min              = 1
  subnets                  = module.vpc.private_subnets

  # enable_rolling_updates = true # This is the default setting and does not need to be explicitly defined.
}

module "asg_without_rolling_updates" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-ec2_asg//?ref=v0.12.1"

  ec2_os                   = "amazon2"
  install_codedeploy_agent = true
  instance_type            = "t2.micro"
  name                     = "rolling_updates_disabled"
  security_groups          = [module.security_groups.private_web_security_group_id]
  scaling_max              = 2
  scaling_min              = 1
  subnets                  = module.vpc.private_subnets

  enable_rolling_updates = false # This will ensure rolling updates are not performed.
}

