# Create a VPC for our application
resource "aws_vpc" "regnal" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "regnal"
  }
}

resource "aws_vpc_dhcp_options" "regnal" {
  domain_name         = "regnal.local"
  domain_name_servers = ["AmazonProvidedDNS"]
}

resource "aws_vpc_dhcp_options_association" "regnal" {
  vpc_id          = "${aws_vpc.regnal.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.regnal.id}"
}

# Create a VPC subnet, we will use this subnet with an internet gateway to allow
# public traffic
resource "aws_subnet" "regnal" {
  vpc_id     = "${aws_vpc.regnal.id}"
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "regnal"
  }
}

# Create a security group resource to allow SSH, TLS, and Puppet traffic
resource "aws_security_group" "regnal" {
  name        = "regnal"
  description = "Allow SSH, TLS, and Puppet inbound traffic"
  vpc_id      = "${aws_vpc.regnal.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH traffic"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Allow internal TLS traffic"
  }

  ingress {
    from_port   = 8140
    to_port     = 8140
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Allow internal puppet traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow any outbound traffic"
  }

  tags = {
    Name = "regnal"
  }
}

resource "aws_security_group" "regnal_web" {
  name        = "regnal_web"
  description = "Allow TLS traffic"
  vpc_id      = "${aws_vpc.regnal.id}"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow external TLS traffic"
  }

  tags = {
    Name = "regnal-web"
  }
}


resource "aws_internet_gateway" "regnal" {
  vpc_id = "${aws_vpc.regnal.id}"
  tags = {
    Name = "regnal"
  }
}

resource "aws_route_table" "regnal" {
  vpc_id = "${aws_vpc.regnal.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.regnal.id}"
  }
  tags = {
    Name = "regnal"
  }
}

resource "aws_route_table_association" "regnal" {
  subnet_id      = "${aws_subnet.regnal.id}"
  route_table_id = "${aws_route_table.regnal.id}"
}
