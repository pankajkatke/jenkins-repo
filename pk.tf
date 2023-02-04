provider "aws" {
          region = "ap-south-1"
          access_key = "AKIAQQMBRQU46WOSCKIJ"
          secret_key = "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"
}

resource "aws_vpc" "publicvpc"{
          cidr_block = "10.10.0.0/16"
          tags = {
     name = "publicvpc"
}
}
resource "aws_subnet" "publicsubnet"{
          vpc_id = "${aws_vpc.publicvpc.id}"
          cidr_block = "10.10.1.0/24"
          availability_zone = "ap-south-1a"
          tags = {
        name = "publicsubnet"
}
}
resource "aws_subnet" "privatesubnet"{
          vpc_id = "${aws_vpc.publicvpc.id}"
          cidr_block = "10.10.2.0/24"
          availability_zone = "ap-south-1a"
          tags = {
      name = "publicsubnet"
}
}
resource "aws_internet_gateway" "myigw" {
          vpc_id = "${aws_vpc.publicvpc.id}"
          tags = {
       name = "myigw"
}
}
resource "aws_route_table" "publicrt"{
          vpc_id = "${aws_vpc.publicvpc.id}"
          route {
          cidr_block = "0.0.0.0/0"
          gateway_id = "${aws_internet_gateway.myigw.id}"
}
}

resource "aws_route_table_association" "public_routing2"{
          subnet_id = "${aws_subnet.publicsubnet.id}"
          route_table_id = "${aws_route_table.publicrt.id}"
}

resource "aws_route_table_association" "public_routing1"{
          subnet_id = "${aws_subnet.privatesubnet.id}"
          route_table_id = "${aws_route_table.publicrt.id}"
}

resource "aws_security_group" "sg" {
  name        = "sg"
  description = "Allow TLS inbound traffic"
  vpc_id = "${ aws_vpc.publicvpc.id}"

  ingress {
    description      = "ssh from VPC"
    from_port        = 20
    to_port          = 20
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "httpd from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "tomcat from VPC"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
      cidr_blocks = [ "0.0.0.0/0" ]
      description = "All_traffic"
      from_port = 0
      protocol = "-1"
      self = false
      to_port = 0


    }

  tags = {
    Name = "sg"
  }
}


resource "aws_instance" "new" {
          ami = "ami-01a4f99c4ac11b03c"
          instance_type = "t2.micro"
          key_name = "Mumbai-Key-Pair11"
          subnet_id = "${aws_subnet.publicsubnet.id}"
          security_groups = [aws_security_group.sg.id]
          user_data = <<EOF
  #!/bin/bash
 yum update -y
 sudo yum install httpd -y
 cd/
 sudo mkdir naman
 cd naman
 wget https://www.tooplate.com/zip-templates/2121_wave_cafe.zip
 unzip 2121_wave_cafe.zip
 sudo cp -r ./2121_wave_cafe/* /var/www/html/
 sudo service httpd start
 sudo systemctl restart httpd

EOF
}

resource "aws_eip" "lb" {
  instance = "${aws_instance.new.id}"
  vpc      = true
}

output "public_ip" {
  value = aws_instance.new.public_ip
}


