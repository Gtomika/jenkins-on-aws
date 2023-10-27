module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"
  key_name           = "${var.jenkins_name_prefix}-key-pair"
  create_private_key = true
}

resource "local_sensitive_file" "private_key_file" {
  filename = "jenkins_instance_private_key.pem"
  content = module.key_pair.private_key_pem
}

resource "aws_security_group" "jenkins_security_group" {
  name = "${var.jenkins_name_prefix}-security-group"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "ingress_http_rule" {
  security_group_id = aws_security_group.jenkins_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ingress_http_jenkins_port_rule" {
  security_group_id = aws_security_group.jenkins_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8080
  to_port           = 8080
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ingress_ssh_rule" {
  security_group_id = aws_security_group.jenkins_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = var.ssh_ip_whitelist
}

resource "aws_security_group_rule" "egress_all_rule" {
  security_group_id = aws_security_group.jenkins_security_group.id
  type              = "egress"
  protocol          = "all"
  from_port         = 0
  to_port           = 65535
  cidr_blocks       = ["0.0.0.0/0"]
}

# can be changed to other Jenkins compatible AMI, but this one is free tier
data "aws_ami" "amazon_linux_2_latest_ami" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_launch_template" "jenkins_launch_template" {
  name = "${var.jenkins_name_prefix}-launch-template"

  image_id = data.aws_ami.amazon_linux_2_latest_ami.id
  instance_type = var.jenkins_instance_type

  key_name = module.key_pair.key_pair_name

  disable_api_stop        = false
  disable_api_termination = false

  # Could enable this block if the instance needed access to other AWS resources
#  iam_instance_profile {
#    name = "test"
#  }

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.jenkins_security_group.id]
    subnet_id = var.public_subnet_id
  }

  user_data = filebase64("${path.module}/install_jenkins.sh")
}

resource "aws_instance" "jenkins_instance" {
  launch_template {
    id = aws_launch_template.jenkins_launch_template.id
    version = "$Latest"
  }
  tags = {
    Name = "${var.jenkins_name_prefix}-instance"
  }
}
