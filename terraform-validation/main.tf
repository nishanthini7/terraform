provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "mainvpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "mainvpc"
  }
}

# Create subnets within the VPC
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.mainvpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public Subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.mainvpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "Private Subnet"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "my_internet_gateway" {
  vpc_id = aws_vpc.mainvpc.id
  tags = {
    Name = "My Internet Gateway"
  }
}

# Create a route table for the public subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.mainvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_internet_gateway.id
  }
  tags = {
    Name = "Public Route Table"
  }
}

# Associate the route table with the public subnet
resource "aws_route_table_association" "public_subnet_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Security group for the web server
resource "aws_security_group" "sg1" {
  name        = "web-server-sg1"
  description = "Security group for web server"
  vpc_id      = aws_vpc.mainvpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Launch the EC2 instance in the public subnet with user_data for Nginx
resource "aws_instance" "web_server" {
  ami                         = "ami-04b4f1a9cf54c11d0"  
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg1.id]
  key_name                    = "my-keypair"

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
  EOF

  tags = {
    Name = "Web Server"
  }
}

# Security group for the DB server
resource "aws_security_group" "sg2" {
  name        = "db-server-sg2"
  description = "Security group for database server"
  vpc_id      = aws_vpc.mainvpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Launch the EC2 instance in the private subnet with user_data for MySQL
resource "aws_instance" "DB_server" {
  ami                         = "ami-04b4f1a9cf54c11d0"  
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.private_subnet.id
  associate_public_ip_address = false  # No public IP for DB server
  vpc_security_group_ids      = [aws_security_group.sg2.id]
  key_name                    = "my-keypair"

  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update -y
    sudo apt-get install -y mysql-server
    sudo systemctl start mysql
    sudo systemctl enable mysql
    sudo mysql_secure_installation
  EOF

  tags = {
    Name = "DB Server"
  }
}

# Terraform backend configuration (S3)
terraform {
  backend "s3" {
    bucket = "terraformvalidation001"
    key    = "my-terraform-project"
    region = "us-east-1"
  }
}

# Output the public IP of the web server
output "public_ip" {
  value       = aws_instance.web_server.public_ip
  description = "Public IP address of the web server"
}


