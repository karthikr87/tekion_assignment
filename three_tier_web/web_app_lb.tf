resource "aws_security_group" "espm_sg_web_lb" {
  name = "espm_sg_web_lb"
  vpc_id = aws_vpc.espm_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
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
