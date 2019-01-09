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

module "instance_replacement" {
  source = "../../module"
  name   = "ASGIR-${random_string.rstring.result}"
}

module "vpc" {
  source   = "git@github.com:rackspace-infrastructure-automation/aws-terraform-vpc_basenetwork?ref=master"
  vpc_name = "ASGIR-${random_string.rstring.result}"
}

module "security_groups" {
  source        = "git@github.com:rackspace-infrastructure-automation/aws-terraform-security_group//?ref=master"
  resource_name = "ASGIR-${random_string.rstring.result}"
  vpc_id        = "${module.vpc.vpc_id}"
}

module "asg" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-ec2_asg//?ref=master"

  ec2_os                   = "amazon"
  image_id                 = "${data.aws_ami.amz_linux_2.image_id}"
  install_codedeploy_agent = "True"
  instance_type            = "t2.micro"
  resource_name            = "ASGIR-${random_string.rstring.result}"
  security_group_list      = ["${module.security_groups.private_web_security_group_id}"]
  scaling_max              = "2"
  scaling_min              = "1"
  subnets                  = ["${element(module.vpc.public_subnets, 0)}", "${element(module.vpc.public_subnets, 1)}"]
}
