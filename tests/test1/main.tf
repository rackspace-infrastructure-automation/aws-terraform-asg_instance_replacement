terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  version = "~> 3.0"
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

module "instance_replacement" {
  source = "../../module"

  name = "ASGIR-${random_string.rstring.result}"
}

module "vpc" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-vpc_basenetwork?ref=v0.12.1"

  name = "ASGIR-${random_string.rstring.result}"
}

module "security_groups" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-security_group//?ref=v0.12.0"

  name   = "ASGIR-${random_string.rstring.result}"
  vpc_id = module.vpc.vpc_id
}

module "asg" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-ec2_asg//?ref=v0.12.1"

  ec2_os                   = "amazon"
  install_codedeploy_agent = true
  instance_type            = "t2.micro"
  name                     = "ASGIR-${random_string.rstring.result}"
  scaling_max              = 2
  scaling_min              = 1
  security_groups          = [module.security_groups.private_web_security_group_id]
  subnets                  = module.vpc.private_subnets
}
