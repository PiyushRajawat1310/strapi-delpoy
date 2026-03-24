provider "aws" {
  region = var.aws_region
}

# Generate SSH key
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Generate unique suffix
resource "random_id" "key_suffix" {
  byte_length = 2
}

# Create AWS Key Pair
resource "aws_key_pair" "generated_key" {
  key_name   = "strapi-auto-key-${random_id.key_suffix.hex}"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  owners = ["amazon"]
}

# Security Group
resource "aws_security_group" "strapi_sg" {
  name_prefix = "strapi-sg-"
  description = "Allow SSH, HTTP, Strapi"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance
resource "aws_instance" "strapi_ec2" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"  # safer for free tier

  key_name = aws_key_pair.generated_key.key_name

  vpc_security_group_ids = [aws_security_group.strapi_sg.id]

  associate_public_ip_address = true

  user_data = <<-EOF
#!/bin/bash

# Update system
yum update -y

# Install Docker
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# 🔥 FIX DOCKER NETWORK ISSUE
iptables -P FORWARD ACCEPT

# Wait for Docker
until docker info >/dev/null 2>&1; do
  sleep 5
done

# Pull latest image
docker pull ${DOCKER_IMAGE}

# Stop old container if exists
docker stop strapi || true
docker rm strapi || true

# Run Strapi container
docker run -d \
  -p 1337:1337 \
  --name strapi \
  --restart always \
  --env NODE_ENV=production \
  --env APP_KEYS=testKey1,testKey2 \
  --env API_TOKEN_SALT=testSalt \
  --env ADMIN_JWT_SECRET=testSecret \
  --env TRANSFER_TOKEN_SALT=testSalt \
  --env JWT_SECRET=testJWT \
  --env ENCRYPTION_KEY=testEncryption \
  ${DOCKER_IMAGE}

EOF

  tags = {
    Name = "Strapi-Server"
  }
}
