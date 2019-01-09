output "asg" {
  value       = "${module.asg.asg_name_list[0]}"
  description = "outputs the name of the ASGs in a list"
}

output "lambda" {
  value       = "ASGIR-${random_string.rstring.result}"
  description = "outputs the name of the lambda"
}
