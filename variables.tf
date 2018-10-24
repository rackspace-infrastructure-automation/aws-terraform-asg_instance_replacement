variable "cloudwatch_log_retention" {
  description = "The number of days to retain Cloudwatch Logs for this instance."
  type        = "string"
  default     = "30"
}

variable "name" {
  description = "Name to use for resources"
  type        = "string"
  default     = "tf-aws-asg-instance-replacement"
}

variable "schedule" {
  description = "Schedule for running the Lambda function"
  type        = "string"
  default     = "rate(1 minute)"
}

variable "timeout" {
  description = "Lambda function timeout"
  type        = "string"
  default     = "60"
}
