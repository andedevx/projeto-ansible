terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.7"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_instance" "dev-server2" {
  ami           = "ami-080e1f13689e07408"
  instance_type = "t2.micro"
  key_name = "ec2-key-dev"

  vpc_security_group_ids = [
    "grp_sec_dev"
  ]

  provisioner "local-exec" {
    command = <<-EOT
      if ! grep -q "${aws_instance.dev-server2.public_dns} ansible_ssh_user=ubuntu ansible_ssh_private_key_file=./ssh/my_key" hosts; then
        echo -e "\n${aws_instance.dev-server2.public_dns} ansible_ssh_user=ubuntu ansible_ssh_private_key_file=./ssh/my_key" >> hosts
      fi
      sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' hosts
    EOT
  }

  depends_on = [aws_instance.dev-server2]
}

resource "aws_key_pair" "key-Dev" {
    key_name = "ec2-key-dev"
    public_key = file("./ssh/my_key.pub")
}

resource "aws_security_group" "grp_sec_dev" {
  name = "grp_sec_dev"
  description = "Ambiente Dev"
  ingress{
      cidr_blocks = [ "0.0.0.0/0" ]
      ipv6_cidr_blocks = [ "::/0" ]
      from_port = 0
      to_port = 0
      protocol = "-1"
  }
  egress{
      cidr_blocks = [ "0.0.0.0/0" ]
      ipv6_cidr_blocks = [ "::/0" ]
      from_port = 0
      to_port = 0
      protocol = "-1"
  }
  tags = {
    Name = "grp_sec_dev"
  }
}

output "ip_publico" {
  value = aws_instance.dev-server2.public_ip
}

output "public_dns" {
  value = aws_instance.dev-server2.public_dns
}

