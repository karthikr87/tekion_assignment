provider "aws" {
  region = var.region
}
resource "aws_vpc" "espm_vpc" {
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"
    enable_dns_support = "true"
    enable_dns_hostnames = "true"
    tags = {
      Name = "espm_vpc"
    }
}
resource "aws_internet_gateway" "espm_IG" {
  vpc_id = aws_vpc.espm_vpc.id
  tags = {
    Name = "espm_IG"
  }
}
resource "aws_subnet" "espm_pub_subnet" {
  count = length(var.espm_public_subnets)
  vpc_id = aws_vpc.espm_vpc.id
  map_public_ip_on_launch = "true"
  availability_zone = var.availability_zones[count.index]
  cidr_block = var.espm_public_subnets[count.index]
  tags = {
     Name = "espm_pub_subnet_${count.index}"
  }
}
resource "aws_route_table" "espm_pub_route_table" {
  vpc_id = aws_vpc.espm_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.espm_IG.id
  }
  tags = {
    Name = "espm_pub_route_table"
  }
}
resource "aws_route_table_association" "espm_pub_route_associate" {
  count = length(var.espm_public_subnets)

  subnet_id = element(aws_subnet.espm_pub_subnet.*.id, count.index)
  route_table_id = aws_route_table.espm_pub_route_table.id

}
resource "aws_subnet" "espm_pri_subnet" {
  count = length(var.espm_private_subnets)
  vpc_id = aws_vpc.espm_vpc.id
  availability_zone = var.availability_zones[count.index]
  cidr_block = var.espm_private_subnets[count.index]
  tags = {
     Name = "espm_pri_subnet_${count.index}"
  }
}
resource "aws_eip" "espm_eip_nat" {
  vpc = true
}
resource "aws_nat_gateway" "espm_nat_gw" {
  allocation_id = aws_eip.espm_eip_nat.id
  subnet_id =  aws_subnet.espm_pub_subnet.1.id
}
resource "aws_route_table" "espm_pri_route_table" {
  vpc_id = aws_vpc.espm_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.espm_nat_gw.id
  }
  tags = {
    Name = "espm_pri_route_table"
  }
}
resource "aws_route_table_association" "espm_pri_route_associate" {
  count = length(var.espm_private_subnets)
  subnet_id = element(aws_subnet.espm_pri_subnet.*.id, count.index)
  route_table_id = aws_route_table.espm_pri_route_table.id

}
