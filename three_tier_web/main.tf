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
resource "aws_security_group" "espm_sg_web_lb" {
  name = "espm_sg_web_lb"
  vpc_id = aws_vpc.espm_vpc.id
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
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  depends_on = [aws_internet_gateway.espm_IG]

}
resource "aws_lb" "espm_web_lb" {
  name = "espm-web-lb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.espm_sg_web_lb.id]
  subnets = aws_subnet.espm_pub_subnet.*.id
  tags = {
    Name = "EXTERNAL-ALB"
  }
}
resource "aws_alb_target_group" "espm_web_alb_tg" {
  name     = "espm-web-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.espm_vpc.id
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.espm_web_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.espm_web_alb_tg.arn
  }
}
resource "aws_security_group" "espm_sg_backend_lb" {
  name = "espm_sg_backend_lb"
  vpc_id = aws_vpc.espm_vpc.id
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [aws_security_group.espm_sg_web_lb.id]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.espm_sg_web_lb.id]
  }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.espm_sg_web_lb.id]
  }

}
resource "aws_lb" "espm_app_backend_lb" {
  name = "espm-app-lb"
  internal = true
  load_balancer_type = "application"
  security_groups = [aws_security_group.espm_sg_backend_lb.id]
  subnets = aws_subnet.espm_pri_subnet.*.id
  tags = {
    Name = "INTERNAL-ALB"
  }
}
resource "aws_alb_target_group" "espm_alb_tg" {
  name     = "espm-backend-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.espm_vpc.id
}

resource "aws_lb_listener" "backed_end" {
  load_balancer_arn = aws_lb.espm_app_backend_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.espm_alb_tg.arn
  }
}
resource "aws_security_group" "espm_asg_config_sg" {
  name = "espm_asg_config_sg"
  vpc_id = aws_vpc.espm_vpc.id
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    security_groups = [aws_security_group.espm_sg_web_lb.id]
  }
}
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_launch_configuration" "espm_web_config" {
  name          = "web_config"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  security_groups = [aws_security_group.espm_asg_config_sg.id]
}

resource "aws_autoscaling_group" "espm_web_asg" {
  # Force a redeployment when launch configuration changes.
  # This will reset the desired capacity if it was changed due to
  # autoscaling events.
  name = "${aws_launch_configuration.espm_web_config.name}-asg"
  min_size             = 2
  desired_capacity     = 2
  max_size             = 4
  health_check_type    = "EC2"
  launch_configuration = aws_launch_configuration.espm_web_config.name
  vpc_zone_identifier  = aws_subnet.espm_pri_subnet.*.id

  # Required to redeploy without an outage.
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_autoscaling_attachment" "espm_asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.espm_web_asg.id
  alb_target_group_arn   = aws_alb_target_group.espm_web_alb_tg.arn
}
resource "aws_autoscaling_policy" "bat" {
  name                   = "espm-web-autoscaling-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.espm_web_asg.name
}
