aws_key_id = "<your AWS key id>"
aws_secret_key = "<your AWS secret key>"

# can be deleted if you don't assume role with Terraform
aws_terraform_role_arn = "<your AWS role ARN for Terraform>"
aws_assume_role_external_id = "<your role external ID>"

aws_region = "<your AWS region>"
vpc_id = "<your VPC ID, which is in the selected region>"
# should be in the selected VPC, across multiple AZs, for high availability
public_subnet_ids = ["<your public subnet ID which is in the selected VPC>"]

jenkins_name_prefix = "jenkins"
ip_whitelist = ["<your IP you want to SSH from>"]
# this instance type is free tier eligible
jenkins_controller_instance_type = "t2.micro"
# Amazon Linux 2023, user data script is compatible with this AMI!
jenkins_ami = "ami-04376654933b081a7"
# this instance type is free tier eligible
jenkins_worker_instance_type = "t2.micro"
# EC2 fleet plugin also allows to configure these as well, but you can put a limit here too
jenkins_workers_min = 0
jenkins_workers_max = 2
# ASG will have no instances unless Jenkins needs some
# can be changed to 1 for example to always have a standby instance -> more cost though
jenkins_workers_desired = 0
