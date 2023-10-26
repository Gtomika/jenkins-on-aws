output "ssh_user" {
  value = var.ssh_user
}

output "jenkins_instance_private_key_pem" {
  value = nonsensitive(module.key_pair.private_key_pem)
}

output "jenkins_instance_public_dns" {
  value = aws_instance.jenkins_instance.public_dns
}