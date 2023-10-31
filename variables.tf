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

variable "public_subnet_ids" {
  type = list(string)
  description = "IDs of public subnets from the selected VPC"
}

variable "jenkins_name_prefix" {
  type = string
  description = "Name prefix of Jenkins related resources"
}

variable "ip_whitelist" {
  type = list(string)
  description = "List of CIDR blocks that should be allowed to SSH into the Jenkins instance and connect to workers"
}

variable "jenkins_controller_instance_type" {
  type = string
  description = "EC2 instance type for the Jenkins controller instance"
}

variable "jenkins_ami" {
  type = string
  description = "AMI for the jenkins controller and workers"
}

variable "jenkins_worker_instance_type" {
  type = string
  description = "EC2 instance type for the workers"
}

variable "jenkins_workers_min" {
  type = number
  description = "At least this much worker instances must be running"
}

variable "jenkins_workers_max" {
  type = number
  description = "At most this much worker instances must be running"
}

variable "jenkins_workers_desired" {
  type = number
  description = "Desired amount of worker instances. Must be between min and max (can be equal to them)"
}