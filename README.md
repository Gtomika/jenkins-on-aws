# Jenkins on AWS

This repository contains Terraform code that sets up Jenkins on AWS. A main (controller) instance hosts Jenkins, 
and an autoscaling group is created for worker instances.

**Warning**: this is not a production ready setup. Some things can be improved:

 - Security: worker instances should be in a private subnet which has a NAT gateway. This setup saves on costs. 
 - High availability: a single instance controller should be configured in such a way that is replaced if it shuts down.
 - Costs: using spot instances for workers could reduce costs.

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

# How to unlock Jenkins

This part is applicable only if Terraform successfully applied the configuration.

A key pair will be created (private key saved as local file), which can be used to SSH into the Jenkins
instance. The key pair created uses the *PEM* format. If on Windows and using *Putty*, it will have to
be converted to *PPK* following [this guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/putty.html).

Terraform will output the public DNS address of the Jenkins instance with key `jenkins_instance_public_dns`.
This address and the port 8080 can be used to connect through the browser.

Enter the one time password to unlock Jenkins. It can be found with
`sudo cat /var/lib/jenkins/secrets/initialAdminPassword` after SSH into the instance. One Jenkins is unlocked, 
you can proceed with configuring it.

# How to configure EC2 Fleet plugin

The [EC2 fleet plugin](https://plugins.jenkins.io/ec2-fleet/) can create and terminate worker instances on demand. This 
can be installed on the Jenkins controller. After that, you can set up a "cloud" with the EC2 Fleet type.

To do so, an auto-scaling group must be specified: this group will house the worker instances. The Terraform configuration 
already creates this ASG which is ready to use.

Here is an example way this EC2 fleet plugin can be configured, after it is installed:

- Manage Jenkins -> Cloud -> New Cloud -> EC2 Fleet
- Set any name you like.
- Do not set AWS credentials: they will be obtained from the instance profile, which Terraform created.
- For EC2 Fleet, select the Jenkins worker ASG, which was created by Terraform.
- For launcher, create an SSH username and private key credentials and use that. Username should be `ec2-user`, and 
the private key contents can be copied from `jenkins_instance_private_key.pem`. Terraform created this file.
- Also for launcher, expand `Advanced`, and add the Java path: `/usr/lib/jvm/java-11-amazon-corretto.x86_64/bin/java` (the 
script `worker_setup.sh` installed Java 11 in this location)
- Select to use private IP (no need for workers to have public IP).
- Fleet maximum and minimum amounts can be configured.
- There are several other options that can be modified, which I left on defaults.

A successfully configured fleet will scale down to 0 when no builds are going on for a while:

![scaled down fleet](/img/ec2_fleet_empty.png)

When a job comes in with the label of the EC2 fleet (in this example, `amazon-linux-maven-java-21`), the EC2 
fleet will provision an instance:

![scaled_up_fleet](/img/ec2_fleet_used.png)

# Tear down infrastructure

When not actively using it, the recommended way is to stop the Jenkins controller EC2 instance: this setup will not incur 
any significant charges if the instance is stopped. Later, the instance can be started again without data loss. 
However, note that the IP address and DNS name will change (if you don't want this, elastic IP can be used, but costs 
will increase).

The idle worker instances will shut down automatically after a short time.

In case of fully destroying the infrastructure is needed:

```
terraform destroy --var-file=inputs.tfvars
```

This will permanently delete every related resource from the AWS account. If you re-create it later, there will 
be a new key pair, a new IP for the instance, and so on.