provider "aws" {
  
  region  = "ap-south-1"
  profile="Garg"
}

resource "aws_vpc" "virtualpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "vpc1"
  }
}

resource "aws_subnet" "publicsubnet" {
  vpc_id     = "${aws_vpc.virtualpc.id}"
  cidr_block = "192.168.0.0/24"
availability_zone ="ap-south-1a"
map_public_ip_on_launch=true
tags = {
    Name = "publicsubnet"
  }
}

resource "aws_subnet" "priavtesubnet" {
  vpc_id     = "${aws_vpc.virtualpc.id}"
  cidr_block = "192.168.1.0/24"
availability_zone="ap-south-1b"
tags = {
    Name = "privatesubnet"
  }
}

resource "aws_internet_gateway" "internetgw" {
  vpc_id = "${aws_vpc.virtualpc.id}"

  tags = {
    Name = "gw"
  }
}

resource "aws_route_table" "routing" {
  vpc_id = "${aws_vpc.virtualpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.internetgw.id}"
  }

  tags = {
    Name = "routeoutside"
  }
}

resource "aws_route_table_association" "outside" {
  subnet_id      = aws_subnet.publicsubnet.id
  route_table_id = aws_route_table.routing.id
}


resource "aws_security_group" "publicsg" {
  name        = "publicsg"
  description = "Allow "
  vpc_id      = "${aws_vpc.virtualpc.id}"

  ingress {
   description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
   description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    description = "TLS from VPC"
    from_port   = 0 
    to_port     = 65535
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
    Name = "wordpress"
  }
}





resource "aws_security_group" "privatesg" {
  name        = "privatesg"
  description = "NAllow "
  vpc_id      = "${aws_vpc.virtualpc.id}"

ingress {
    description = "TLS from VPC"
    from_port   = 3306
    to_port     = 3306
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
    Name = "sql"
  }
}


resource "aws_instance" "wordpressPublic" {
ami = "ami-03c36a740967e1c6a"
instance_type = "t2.micro"
key_name = "dops"
subnet_id = "${aws_subnet.publicsubnet.id}"
security_groups = ["${aws_security_group.publicsg.id}"]


tags = {
   Name = "wordpress"
  }
}


resource "aws_instance" "database" {
ami = "ami-04b586292a4b837b5"
instance_type = "t2.micro"
key_name = "dops"
subnet_id = "${aws_subnet.priavtesubnet.id}"
security_groups = ["${aws_security_group.privatesg.id}"]


tags = {
   Name = "sql"
  }
}
