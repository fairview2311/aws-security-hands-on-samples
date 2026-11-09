resource "aws_lb" "main" {
  name               = "${var.project}-alb"
  load_balancer_type = "application"
  # 内部の ALB にする（インターネットから直接届かない。CloudFront の VPC オリジンだけが届く）
  internal        = true
  security_groups = [aws_security_group.alb.id]
  subnets         = aws_subnet.private[*].id
}

resource "aws_lb_target_group" "app" {
  name     = "${var.project}-app"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path    = "/healthz"
    matcher = "200"
  }
}

resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app.id
  port             = 8000
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
