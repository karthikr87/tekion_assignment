resource "aws_security_group" "espm_sg_backend_lb" {
  name = "espm_sg_backend_lb"
  vpc_id = aws_vpc.espm_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
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
resource "aws_alb_target_group" "espm_backend_alb_tg" {
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
    target_group_arn = aws_alb_target_group.espm_backend_alb_tg.arn
  }
}
