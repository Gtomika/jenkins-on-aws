# Jenkins on AWS

This repository contains Terraform code that sets up Jenkins on AWS. It is based on 
[this article](https://www.jenkins.io/doc/tutorials/tutorial-for-installing-jenkins-on-AWS/),
which is implemented in Terraform.

The key pair created uses the *PEM* format. If on Windows and using *Putty*, it will have to
be converted to *PPK* following [this guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/putty.html).

**Warning**: this is not a production ready setup. Some things can be improved:

 - Security: allow only the minimal required connections for the security group.
 - Jenkins configurations can be improved.
 - High availability: a single instance can be converted to an auto scaling group across multiple AZs.

# How to use

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

In case destroying this infrastructure is needed:

```
terraform destroy --var-file=inputs.tfvars
```

It will ask for confirmation.