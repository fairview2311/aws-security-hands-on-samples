# ALB: 自分の IP アドレスからの HTTP だけを受け付ける
resource "aws_security_group" "alb" {
  name   = "${var.project}-alb"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "HTTP from my IP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2: ALB からのアプリの通信だけを受け付ける
resource "aws_security_group" "app" {
  name   = "${var.project}-app"
  vpc_id = aws_vpc.main.id

  ingress {
    description     = "App from ALB"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# RDS: EC2 からの PostgreSQL の通信だけを受け付ける
resource "aws_security_group" "db" {
  name   = "${var.project}-db"
  vpc_id = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from app"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
}

# VPC エンドポイント: EC2 からの HTTPS だけを受け付ける
resource "aws_security_group" "endpoints" {
  name   = "${var.project}-endpoints"
  vpc_id = aws_vpc.main.id

  ingress {
    description     = "HTTPS from app"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
}
