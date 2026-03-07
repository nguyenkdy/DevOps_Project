provider "aws" {
  region = "ap-southeast-1" 
}

# Tạo mạng ảo VPC
resource "aws_vpc" "k8s_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Project-VPC"
  }
}

# Tạo Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "K8s-Public-Subnet"
  }
}

# Tạo Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.k8s_vpc.id
  tags   = { Name = "K8s-IGW" }
}

# Tạo Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.k8s_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "K8s-Public-RT" }
}

# Liên kết Route Table
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group updated with K8s API port
resource "aws_security_group" "k8s_sg" {
  name        = "k8s-security-group"
  vpc_id      = aws_vpc.k8s_vpc.id

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

  # Required for kubectl control from your machine
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  # Allow all internal traffic within the Security Group
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "k8s_nodes" {
  count         = 3
  ami           = "ami-08d59269edddde222"
  instance_type = "t3.medium"
  
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  associate_public_ip_address = true
  key_name = aws_key_pair.deployer.key_name

  tags = {
    Name = count.index == 0 ? "K8s-Master" : "K8s-Worker-${count.index}"
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

output "instance_ips" {
  value = aws_instance.k8s_nodes[*].public_ip
}

# Auto-generate Combined Ansible Inventory (AWS + Azure)
resource "local_file" "ansible_inventory" {
  content  = <<EOT
[master]
${aws_instance.k8s_nodes[0].public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa

[workers]
${aws_instance.k8s_nodes[1].public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa
${aws_instance.k8s_nodes[2].public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa

[jenkins_azure]
${azurerm_public_ip.jenkins_pip.ip_address} ansible_user=azureuser ansible_ssh_private_key_file=~/.ssh/id_rsa

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOT
  filename = "../ansible/inventory.ini"
}
