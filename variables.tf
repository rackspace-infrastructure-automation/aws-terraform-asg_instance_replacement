variable "cloudwatch_log_retention" {
  description = "The number of days to retain Cloudwatch Logs for this instance."
  type        = number
  default     = 30
}

variable "name" {
  description = "Name to use for resources"
  type        = string
  default     = "asg-instance-replacement"
}

variable "schedule" {
  description = "Schedule for running the Lambda function"
  type        = string
  default     = "rate(1 minute)"
}

variable "timeout" {
  description = "Lambda function timeout"
  type        = number
  default     = 60
}

