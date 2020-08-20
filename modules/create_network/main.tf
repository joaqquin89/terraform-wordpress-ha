# Define and create our VPC
resource "aws_vpc" "default" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  tags = "${merge(map("Name", format("%s", var.vpc_name)),var.vpc_tags)}"
}

#Create PUBLICS SUBNETS IN THE VPC
resource "aws_subnet" "subnet_public_create" {
  count = "${length(var.cidr_blocks_public)}"
  vpc_id = aws_vpc.default.id
  cidr_block = "${element(var.cidr_blocks_public, count.index) }"
  availability_zone = "${element(var.az, count.index)}"
  tags = "${merge(map("Name", element(var.cidr_blocks_public, count.index)), var.vpc_tags)}"
  depends_on=[aws_vpc.default]
}

#Create PRIVATE SUBNETS IN THE VPC
resource "aws_subnet" "subnet_private_create" {
  count = "${length(var.cidr_blocks_private)}"
  vpc_id = aws_vpc.default.id
  cidr_block = "${element(var.cidr_blocks_private, count.index) }"
  availability_zone = "${element(var.az, count.index)}"
  tags = "${merge(map("Name", element(var.cidr_blocks_public, count.index)), var.vpc_tags)}"
  depends_on=[aws_vpc.default]
}

# DEFINE DE INTERNET GATEWAY ONLY IF  CREATE NEW VPC
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.default.id
  tags = "${merge(map("Name", "Internet-Gateway"),var.vpc_tags)}"
  depends_on=[aws_vpc.default, aws_subnet.subnet_public_create]
}

# Define the route table
resource "aws_route_table" "web-public-rt" {
  vpc_id = aws_vpc.default.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
  tags = "${merge(map("Name", "Public-route" ),var.vpc_tags)}"
  depends_on=[aws_internet_gateway.gw]
}

# Assign the route table to the public Subnet
resource "aws_route_table_association" "web-public-rt" {
  count = "${length(var.cidr_blocks_public)}"
  subnet_id = "${element(aws_subnet.subnet_public_create.*.id,count.index)}"
  route_table_id = "${aws_route_table.web-public-rt.id}"
  depends_on=[aws_route_table.web-public-rt]
}

resource "aws_security_group" "nat" {
	name = "nat"
	description = "Allow services from the private subnet through NAT"
	vpc_id = "${aws_vpc.default.id}"

	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["192.20.1.0/25","192.20.1.128/25"]
	}
	ingress {
		from_port = 443
		to_port = 443
		protocol = "tcp"
		cidr_blocks = ["192.20.1.0/25","192.20.1.128/25"]
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}

  tags = "${merge(map("Name", "nat-SG" ),var.vpc_tags)}"
}

resource "aws_instance" "nat-gateway" {
   ami  = "ami-01623d7b"
   instance_type = "t2.micro"
   subnet_id = element(aws_subnet.subnet_public_create.*.id, 0)
   vpc_security_group_ids = [aws_security_group.nat.id]
   associate_public_ip_address = true
   source_dest_check = false
   depends_on=[aws_security_group.nat]
}

# Define the route table for the nat
resource "aws_route_table" "nat-rt" {
  vpc_id = aws_vpc.default.id
  route {
    cidr_block = "0.0.0.0/0"
    instance_id = "${aws_instance.nat-gateway.id}"
  }
  tags = "${merge(map("Name", "private-rt"),var.vpc_tags)}"
  depends_on=[aws_instance.nat-gateway]
}

# Assign the route table to the private subnets
resource "aws_route_table_association" "nat-rt" {
  count = "${length(var.cidr_blocks_private)}"
  subnet_id = "${element(aws_subnet.subnet_private_create.*.id, count.index)}"
  route_table_id = "${aws_route_table.nat-rt.id}"
  depends_on=[aws_route_table.nat-rt]
}