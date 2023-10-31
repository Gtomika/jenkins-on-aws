module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"
  key_name           = "${var.jenkins_name_prefix}-key-pair"
  create_private_key = true
}

resource "local_sensitive_file" "private_key_file" {
  filename = "jenkins_instance_private_key.pem"
  content = module.key_pair.private_key_pem
}

# security group setup

resource "aws_security_group" "jenkins_controller_security_group" {
  name = "${var.jenkins_name_prefix}-controller-security-group"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "ingress_http_rule" {
  security_group_id = aws_security_group.jenkins_controller_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ingress_http_jenkins_port_rule" {
  security_group_id = aws_security_group.jenkins_controller_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8080
  to_port           = 8080
  cidr_blocks       = ["0.0.0.0/0"]
  description = "Allows HTTP traffic to reach Jenkins controller"
}

resource "aws_security_group_rule" "ingress_ssh_rule" {
  security_group_id = aws_security_group.jenkins_controller_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = var.ip_whitelist
  description = "Allows the whitelisted IP ranges to SSH into the Jenkins controller"
}

resource "aws_security_group_rule" "ingress_workers_rule" {
  security_group_id = aws_security_group.jenkins_controller_security_group.id
  type              = "ingress"
  protocol          = "all"
  from_port         = 0
  to_port           = 65535
  source_security_group_id = aws_security_group.jenkins_worker_security_group.id
  description = "Allows the Jenkins workers to reach the controller in any way"
}

resource "aws_security_group_rule" "egress_all_rule" {
  security_group_id = aws_security_group.jenkins_controller_security_group.id
  type              = "egress"
  protocol          = "all"
  from_port         = 0
  to_port           = 65535
  cidr_blocks       = ["0.0.0.0/0"]
  description = "Allows all outgoing traffic from the Jenkins controller"
}

# instance profile setup: it will allow the Jenkins controller instance
# to launch and terminate other instances

data "aws_iam_policy_document" "jenkins_controller_trust_policy" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# According to the Jenkins EC2 Fleet plugin documentation
# These are the minimum required permissions for the Jenkins controller
data "aws_iam_policy_document" "jenkins_controller_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeSpotFleetInstances",
      "ec2:ModifySpotFleetRequest",
      "ec2:CreateTags",
      "ec2:DescribeRegions",
      "ec2:DescribeInstances",
      "ec2:TerminateInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeSpotFleetRequests"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:UpdateAutoScalingGroup"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "iam:ListInstanceProfiles",
      "iam:ListRoles",
      "iam:PassRole"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "jenkins_controller_role" {
  name = "${var.jenkins_name_prefix}-controller-role"
  assume_role_policy = data.aws_iam_policy_document.jenkins_controller_trust_policy.json
  inline_policy {
    name = "${var.jenkins_name_prefix}-inline-policy"
    policy = data.aws_iam_policy_document.jenkins_controller_policy.json
  }
}

resource "aws_iam_instance_profile" "jenkins_controller_instance_profile" {
  name = "${var.jenkins_name_prefix}-controller-instance-profile"
  role = aws_iam_role.jenkins_controller_role.name
}

resource "aws_launch_template" "jenkins_controller_launch_template" {
  name = "${var.jenkins_name_prefix}-controller-launch-template"

  image_id = var.jenkins_ami
  instance_type = var.jenkins_controller_instance_type

  key_name = module.key_pair.key_pair_name

  disable_api_stop        = false
  disable_api_termination = false

  iam_instance_profile {
    name = aws_iam_instance_profile.jenkins_controller_instance_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.jenkins_controller_security_group.id]
    subnet_id = var.public_subnet_ids[0]
  }

  user_data = filebase64("${path.module}/install_jenkins.sh")
}

resource "aws_instance" "jenkins_instance" {
  launch_template {
    id = aws_launch_template.jenkins_controller_launch_template.id
    version = "$Latest"
  }
  tags = {
    Name = "${var.jenkins_name_prefix}-instance"
  }
}

# Worker instances setup

resource "aws_security_group" "jenkins_worker_security_group" {
  name = "${var.jenkins_name_prefix}-worker-security-group"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "worker_ingress_whitelisted_ssh_rule" {
  security_group_id = aws_security_group.jenkins_worker_security_group.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = var.ip_whitelist
  description = "Allows the whitelisted IPs to SSH into the workers for convenience"
}

resource "aws_security_group_rule" "worker_ingress_controller_rule" {
  security_group_id = aws_security_group.jenkins_worker_security_group.id
  type              = "ingress"
  protocol          = "all"
  from_port         = 0
  to_port           = 65535
  source_security_group_id = aws_security_group.jenkins_controller_security_group.id
  description = "Allows the Jenkins controller to be able to reach the workers in any way"
}

resource "aws_security_group_rule" "worker_egress_all_rule" {
  security_group_id = aws_security_group.jenkins_worker_security_group.id
  type              = "egress"
  protocol          = "all"
  from_port         = 0
  to_port           = 65535
  cidr_blocks       = ["0.0.0.0/0"]
  description = "Allows the workers to send any outgoing traffic"
}

resource "aws_launch_template" "jenkins_worker_launch_template" {
  name = "${var.jenkins_name_prefix}-worker-launch-template"

  image_id = var.jenkins_ami
  instance_type = var.jenkins_worker_instance_type

  key_name = module.key_pair.key_pair_name

  disable_api_stop        = false
  disable_api_termination = false

  network_interfaces {
    associate_public_ip_address = false
    security_groups = [aws_security_group.jenkins_worker_security_group.id]
  }

  user_data = filebase64("${path.module}/worker_setup.sh")
}

resource "aws_autoscaling_group" "jenkins_workers_asg" {
  name = "${var.jenkins_name_prefix}-worker-asg"
  min_size = var.jenkins_workers_min
  max_size = var.jenkins_workers_max
  desired_capacity = var.jenkins_workers_desired
  launch_template {
    id = aws_launch_template.jenkins_worker_launch_template.id
    version = "$Latest"
  }
  # FIXME: should be private subnets for more security: however, we can avoid NAT gateway like this
  vpc_zone_identifier = var.public_subnet_ids

  tag {
    key = "managed_by"
    value = "Auto Scaling Group"
    propagate_at_launch = true
  }
  tag {
    key = "Name"
    value = "jenkins-worker"
    propagate_at_launch = true
  }
}