# Jenkins on AWS

This repository contains Terraform code that sets up Jenkins on AWS. It is based on 
[this article](https://www.jenkins.io/doc/tutorials/tutorial-for-installing-jenkins-on-AWS/), which is implemented in Terraform.

**Warning**: this is not a production ready setup. Some things can be improved:

 - Security: allow only the minimal required connections for the security group.
 - High availability: a single instance can be converted to an auto-scaling group across multiple AZs.

# How to create infrastructure

Create an `inputs.tfvars` file where you fill the required values. `sample.inputs.tfvars` can be used as a start.

Initialize Terraform. This is for an S3 backend, but it can be adjusted for other backend types with ease.

```
terraform init \
  -backend-config="<your S3 state bucket>" \
  -backend-config="key=<your state file S3 key>" \
  -backend-config="region=<your AWS region>" \
  -backend-config="access_key=<AWS access key for Terraform to use>" \
  -backend-config="secret_key=<AWS secret key for Terraform to use>"
```

Plan configuration:

```
terraform plan --var-file=inputs.tfvars --out=jenkins.tfplan
```

Apply configuration:

```
terraform apply jenkins.tfplan
```

# How to configure Jenkins

This part is applicable only if Terraform successfully applied the configuration.

A key pair will be created (private key saved as local file), which can be used to SSH into the Jenkins
instance. The key pair created uses the *PEM* format. If on Windows and using *Putty*, it will have to
be converted to *PPK* following [this guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/putty.html).

Terraform will output the public DNS address of the Jenkins instance with key `jenkins_instance_public_dns`.
This address and the port 8080 can be used to connect through the browser.

Proceed with the article, and enter the one time password to unlock Jenkins. It can be found with

```
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

after SSH into the instance.

Additionally, an IAM instance profile is attached to the Jenkins instance, which will allow it to manage other 
EC2 instances: this is a safe way for the Jenkins controller instance to provision worker instances on demand. The 
article suggests using static credentials for this purpose, however, using the EC2 instance profile is a better 
approach. Check this box when configuring the *New cloud* menu:

![checkbox to use instance profile](/img/checkbox.png)

# Tear down infrastructure

When not actively using it, the recommended way is to stop the Jenkins EC2 instance: this setup will not incur 
any significant charges if the instance is stopped. Later, the instance can be started again without data loss.

In case of fully destroying the infrastructure is needed:

```
terraform destroy --var-file=inputs.tfvars
```

This will permanently delete every related resource from the AWS account. If you re-create it later, there will 
be a new key pair, a new DNS for the instance, and so on.