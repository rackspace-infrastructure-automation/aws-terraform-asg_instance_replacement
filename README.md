# aws-terraform-asg\_instance\_replacement

This module is a replacement for the CloudFormation feature that enables rolling updates of Autoscaling Group instances.

This Terraform module automatically replaces old instances when an Auto Scaling Group's Launch Configuration changes. In other words: rolling AMI updates and instance type changes.

It tries to increase an ASG's desired capacity to launch new instances, but will never increase the maximum size, so it should be safe to use on just about any ASG.

It sets old instances as unhealthy one at a time to gradually replace them with new instances.

It waits for new instances to be completely healthy, ready and in service before proceeding to replace more instances. It will wait for ASG lifecycle hooks and Target Group health checks if they are being used.

## Caution

\_\_Use this module with caution; it terminates healthy instances.\_\_

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
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-asg_instance_replacement//?ref=v0.0.2"
}
```

The required `InstanceReplacement` tag is set to true by default within the `aws-terraform-ec2_asg` module beginning with release v0.0.7.  This can be explicitly enabled or disabled via the `enable_rolling_updates` variable, as shown below

``` HCL
module "asg" {
  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-ec2_asg//?ref=v0.0.24"

  ec2_os                 = "amazon"
  enable_rolling_updates = true  # A value of false will disable rolling updates for this ASG.
  resource_name          = "my_asg"
  security_group_list    = ["${module.sg.private_web_security_group_id}"]
  subnets                = ["${module.vpc.private_subnets}"]
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

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| archive | n/a |
| aws | n/a |

## Modules

No Modules.

## Resources

| Name |
|------|
| [archive_file](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) |
| [aws_caller_identity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) |
| [aws_cloudwatch_event_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) |
| [aws_cloudwatch_event_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) |
| [aws_cloudwatch_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) |
| [aws_iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) |
| [aws_iam_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment) |
| [aws_iam_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) |
| [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) |
| [aws_lambda_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) |
| [aws_lambda_permission](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) |
| [aws_region](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cloudwatch\_log\_retention | The number of days to retain Cloudwatch Logs for this instance. | `string` | `"30"` | no |
| name | Name to use for resources | `string` | `"asg-instance-replacement"` | no |
| schedule | Schedule for running the Lambda function | `string` | `"rate(1 minute)"` | no |
| timeout | Lambda function timeout | `string` | `"60"` | no |

## Outputs

No output.
