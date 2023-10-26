aws_key_id = "<your AWS key id>"
aws_secret_key = "<your AWS secret key>"

# can be deleted if you don't assume role with Terraform
aws_terraform_role_arn = "<your AWS role ARN for Terraform>"
aws_assume_role_external_id = "<your role external ID>"

aws_region = "<your AWS region>"
vpc_id = "<your VPC ID, which is in the selected region>"
public_subnet_id = "<your public subnet ID which is in the selected VPC>"

jenkins_name_prefix = "jenkins"
ssh_ip_whitelist = ["<your IP you want to SSH from>"]
# this instance type is free tier eligible
jenkins_instance_type = "t2.micro"
# this is the SSH user for Amazon Linux
ssh_user = "ec2-user"