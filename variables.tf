variable "aws_key_id" {
  type = string
  sensitive = true
  description = "AWS access key ID"
}

variable "aws_secret_key" {
  type = string
  sensitive = true
  description = "AWS secret key"
}

variable "aws_terraform_role_arn" {
  type = string
  description = "ARN of the role Terraform must assume"
}

variable "aws_assume_role_external_id" {
  type = string
  sensitive = true
  description = "Secret required to assume the Terraform role"
}

variable "aws_region" {
  type = string
  default = "Region to deploy to"
}

variable "vpc_id" {
  type = string
  description = "The VPC that will be used, must be in selected region"
}

variable "public_subnet_id" {
  type = string
  description = "ID of a public subnet from the selected VPC"
}

variable "jenkins_name_prefix" {
  type = string
  description = "Name prefix of Jenkins related resources"
}

variable "ssh_ip_whitelist" {
  type = list(string)
  description = "List of CIDR blocks that should be allowed to SSH into the Jenkins instance"
}

variable "jenkins_instance_type" {
  type = string
  description = "EC2 instance type for the Jenkins instance"
}

variable "ssh_user" {
  type = string
  description = "Username to use during SSH"
}