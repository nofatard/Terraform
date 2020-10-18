# 1. create vpc
resource "aws_vpc" "ht-vpc" {
  cidr_block = "10.0.0.0/16"
}

# 2. create internet Gateway
resource "aws_internet_gateway" "ht-gw" {
  vpc_id = aws_vpc.ht-vpc.id

  tags = {
    Name = "httpd-gw"
  }
}



# 3. create custom Route Table
resource "aws_route_table" "ht-rte" {
  vpc_id         = aws_vpc.ht-vpc.id
  
  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.ht-gw.id
  }
    route {
        ipv6_cidr_block  = "::/0"
        gateway_id = aws_internet_gateway.ht-gw.id
    }


     tags = {
    Name = "ht-rte"
  }
}
# 4. create a subnet
resource "aws_subnet" "sub-1" {
  vpc_id     = aws_vpc.ht-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "pub-sub"
  }
}
# 5. associated subnet with Route Table
resource "aws_route_table_association" "abk" {
  subnet_id      = aws_subnet.sub-1.id
  route_table_id = aws_route_table.ht-rte.id
}
# 6. create security groupe to allow port 22, 80
resource "aws_security_group" "ht-Sg" {
  name        = "allow_web"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.ht-vpc.id

  ingress {
    description = "HTTPD"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 ingress {
    description = "SSHD"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-SG"
  }
}
# 7. create a network interface with an ip in the subnet that was create in step 4
resource "aws_network_interface" "ht-int" {
  subnet_id       = aws_subnet.sub-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.ht-Sg.id]

  }
# 8. assign an elastic ip to the network interface create in step 7
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.ht-int.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.ht-gw]
}

output "server_public-IP" {
  value = aws_eip.one.public_ip

}

# 9. create Ubuntu server and install/enable apche2
resource "aws_instance" "web-server" {
  ami           = "ami-0dba2cb6798deb6d8"
  instance_type = "t2.micro"
  availability_zone = "us-east-1b"
  key_name = ""

  network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.ht-int.id
  
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo my very first web server > /var/www/html/index.html'
              EOF 

  tags = {
    Name = "webserver"
  }
}