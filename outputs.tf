output "jenkins_instance_public_dns" {
  value = aws_instance.jenkins_instance.public_dns
}