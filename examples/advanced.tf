terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  version = "~> 2.7"
  region  = "us-west-2"
}

module "instance_replacement_advanced" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-asg_instance_replacement//?ref=v0.12.0"

  cloudwatch_log_retention = 14                # Set custom retention for Lambda logs
  name                     = "MY-ASGIR"        # Set custom name
  schedule                 = "rate(5 minutes)" # Set custom check frequency
  timeout                  = "120"             # Set custom timeout
}

module "vpc" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-vpc_basenetwork//?ref=v0.12.1"

  name = "my_advanced_vpc"
}

module "security_groups" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-security_group//?ref=v0.12.0"

  name   = "my_advanced_sg"
  vpc_id = module.vpc.vpc_id
}

module "asg_with_rolling_updates" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-ec2_asg//?ref=v0.12.1"

  ec2_os                   = "amazon2"
  install_codedeploy_agent = true
  instance_type            = "t2.micro"
  name                     = "rolling_updates_enabled"
  scaling_max              = 2
  scaling_min              = 1
  security_groups          = [module.security_groups.private_web_security_group_id]
  subnets                  = module.vpc.private_subnets

  # enable_rolling_updates = true # This is the default setting and does not need to be explicitly defined.
}

module "asg_without_rolling_updates" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-ec2_asg//?ref=v0.12.1"

  ec2_os                   = "amazon2"
  install_codedeploy_agent = true
  instance_type            = "t2.micro"
  name                     = "rolling_updates_disabled"
  scaling_max              = 2
  scaling_min              = 1
  security_groups          = [module.security_groups.private_web_security_group_id]
  subnets                  = module.vpc.private_subnets

  enable_rolling_updates = false # This will ensure rolling updates are not performed.
}

