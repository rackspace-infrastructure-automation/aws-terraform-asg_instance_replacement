output "asg" {
  description = "outputs the name of the ASGs in a list"
  value       = "${module.asg.asg_name_list[0]}"
}

output "lambda" {
  description = "outputs the name of the lambda"
  value       = "ASGIR-${random_string.rstring.result}"
}
