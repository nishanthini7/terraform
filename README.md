# terraform
Task : 
Use Terraform to provision an AWS infrastructure with:

Networking:
A VPC with a CIDR block of 10.0.0.0/16.
A public subnet (10.0.1.0/24) for web access.
A private subnet (10.0.2.0/24) for database hosting.
An Internet Gateway attached to the public subnet for external access.
Security Groups allowing inbound HTTP (80), SSH (22), and MySQL (3306 for private access).

Compute Resources:

Server 1 (Web Server)
EC2 instance in the public subnet.
Attached a security group allowing HTTP & SSH access.
Uses a Terraform provisioner or cloud-init script to install Nginx upon launch.
Outputs the public IP.

Server 2 (Database Server)
EC2 instance in the private subnet.
Security Group allows MySQL access only from the Web Server.
Uses Terraform provisioner or cloud-init script to install MySQL upon launch.
Store Terraform state in S3 (backend storage) for remote tracking.
