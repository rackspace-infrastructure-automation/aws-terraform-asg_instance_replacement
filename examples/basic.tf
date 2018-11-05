provider "aws" {
  version = "~> 1.2"
  region  = "us-west-2"
}

provider "random" {
  version = "~> 1.0"
}

resource "random_string" "rstring" {
  length      = 16
  special     = false
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
}

data "aws_ami" "amz_linux_2" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*-ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

module "instance_replacement_simple" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-asg_instance_replacement//?ref=v0.0.1"
}

module "vpc" {
  source   = "git@github.com:rackspace-infrastructure-automation/aws-terraform-vpc_basenetwork//?ref=v0.0.6"
  vpc_name = "my_basic_vpc"
}

module "security_groups" {
  source        = "git@github.com:rackspace-infrastructure-automation/aws-terraform-security_group//?ref=v0.0.5"
  resource_name = "my_basic_sg"
  vpc_id        = "${module.vpc.vpc_id}"
}

module "asg_with_rolling_updates" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-ec2_asg//?ref=v0.0.7"

  ec2_os                   = "amazon"
  image_id                 = "${data.aws_ami.amz_linux_2.image_id}"
  install_codedeploy_agent = "True"
  instance_type            = "t2.micro"
  resource_name            = "rolling_updates_enabled"
  security_group_list      = ["${module.security_groups.private_web_security_group_id}"]
  scaling_max              = "2"
  scaling_min              = "1"
  subnets                  = ["${element(module.vpc.public_subnets, 0)}", "${element(module.vpc.public_subnets, 1)}"]

  # enable_rolling_updates = true # This is the default setting and does not need to be explicitly defined.
}

module "asg_without_rolling_updates" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-ec2_asg//?ref=v0.0.7"

  ec2_os                   = "amazon"
  image_id                 = "${data.aws_ami.amz_linux_2.image_id}"
  install_codedeploy_agent = "True"
  instance_type            = "t2.micro"
  resource_name            = "rolling_updates_disabled"
  security_group_list      = ["${module.security_groups.private_web_security_group_id}"]
  scaling_max              = "2"
  scaling_min              = "1"
  subnets                  = ["${element(module.vpc.public_subnets, 0)}", "${element(module.vpc.public_subnets, 1)}"]
  enable_rolling_updates   = false                                                                                    # This will ensure rolling updates are not performed.
}
