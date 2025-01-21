> [!CAUTION]
> This project is end of life. This repo will be deleted on June 2nd 2025.

# aws-terraform-asg\_instance\_replacement

This module is a replacement for the CloudFormation feature that enables rolling updates of Autoscaling Group instances.

This Terraform module automatically replaces old instances when an Auto Scaling Group's Launch Configuration changes. In other words: rolling AMI updates and instance type changes.

It tries to increase an ASG's desired capacity to launch new instances, but will never increase the maximum size, so it should be safe to use on just about any ASG.

It sets old instances as unhealthy one at a time to gradually replace them with new instances.

It waits for new instances to be completely healthy, ready and in service before proceeding to replace more instances. It will wait for ASG lifecycle hooks and Target Group health checks if they are being used.

## Caution

__Use this module with caution; it terminates healthy instances.__

Care must be taken when using this module with certain types of instances, such as RabbitMQ and Elasticsearch cluster nodes. If these instances are using only ephemeral or in-memory storage, then terminating them too quickly could result in data loss.

In this situation, use Auto Scaling Lifecycle Hooks on the instances to wait until everything is truly healthy (e.g. cluster status green) before putting the instance in service.

## Components

### Lambda function

Use this module once per AWS account to create the Lambda function and associated resources required to perform instance replacement.

The Lambda function runs on a schedule to ensure that all enabled ASGs within the AWS account are replacing instances if the launch configuration has changed. For example, if an ASG is changed to use a different AMI, the scheduled function will detect this and start replacing old instances.

The Lambda function is also triggered whenever an instance is launched or terminated. This makes the process event-driven where possible.

### ASG tags

Add an `InstanceReplacement` tag to an ASG to enable instance replacement. If the value is one of `0, disabled, false, no, off` then it will be disabled. Any other value, including a blank string, will enable instance replacement for that ASG.

## Example

``` HCL

# Create the Lambda function and associated resources once per region.

module "asg_instance_replacement" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-asg_instance_replacement//?ref=v0.12.0"
}
```

The required `InstanceReplacement` tag is set to true by default within the `aws-terraform-ec2_asg` module beginning with release v0.0.7.  This can be explicitly enabled or disabled via the `enable_rolling_updates` variable, as shown below

``` HCL
module "asg" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-ec2_asg//?ref=v0.12.1"

  ec2_os                 = "amazon"
  enable_rolling_updates = true  # A value of false will disable rolling updates for this ASG.
  name                   = "my_asg"
  security_groups        = [module.sg.private_web_security_group_id]
  subnets                = module.vpc.private_subnets
}
```

To enable this functionality on ASGs created directly, add the `InstanceReplacement` tag with a true value.

``` HCL
resource "aws_autoscaling_group" "asg" {
  ...

  tag {
    key                 = "InstanceReplacement"
    value               = "true"
    propagate_at_launch = false
  }
  ...
}
```

Full working references are available at [examples](examples)

## Terraform 0.12 upgrade

There should be no changes required to move from previous versions of this module to version 0.12.0 or higher.

## Providers

| Name | Version |
|------|---------|
| archive | n/a |
| aws | >= 2.7.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| cloudwatch\_log\_retention | The number of days to retain Cloudwatch Logs for this instance. | `number` | `30` | no |
| name | Name to use for resources | `string` | `"asg-instance-replacement"` | no |
| schedule | Schedule for running the Lambda function | `string` | `"rate(1 minute)"` | no |
| timeout | Lambda function timeout | `number` | `60` | no |

## Outputs

No output.

