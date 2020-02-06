resource "aws_security_group" "espm_backend_asg_config_sg" {
  name = "espm_backend_asg_config_sg"
  vpc_id = aws_vpc.espm_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.espm_sg_backend_lb.id]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = [aws_security_group.bastion-sg.id]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# data "aws_ami" "ubuntu" {
#   most_recent = true
#
#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
#   }
#
#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
#
#   owners = ["099720109477"] # Canonical
# }

resource "aws_launch_configuration" "espm_backend_config" {
  name_prefix          = "backend_config"
  image_id      =  "ami-0620d12a9cf777c87"
  instance_type = "t2.micro"
  user_data = file("install_docker.sh")
  key_name = aws_key_pair.bastion_key.key_name
  security_groups = [aws_security_group.espm_backend_asg_config_sg.id]
}

resource "aws_autoscaling_group" "espm_backend_asg" {
  # Force a redeployment when launch configuration changes.
  # This will reset the desired capacity if it was changed due to
  # autoscaling events.
  name = "${aws_launch_configuration.espm_backend_config.name}-asg"
  min_size             = 2
  desired_capacity     = 2
  max_size             = 5
  health_check_type    = "EC2"
  launch_configuration = aws_launch_configuration.espm_backend_config.name
  vpc_zone_identifier  = aws_subnet.espm_pri_subnet.*.id

  # Required to redeploy without an outage.
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_autoscaling_attachment" "espm_backend_asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.espm_backend_asg.id
  alb_target_group_arn   = aws_alb_target_group.espm_backend_alb_tg.arn
}
resource "aws_autoscaling_policy" "backend" {
  name                   = "espm-backend-autoscaling-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.espm_backend_asg.name
}
