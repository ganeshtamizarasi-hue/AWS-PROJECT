# ─────────────────────────────────────────────────────────────
# Application Load Balancer
# ─────────────────────────────────────────────────────────────
resource "aws_lb" "main" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name = "${var.environment}-alb"
  }
}

# ─────────────────────────────────────────────────────────────
# Blue Target Group (LIVE)
# ─────────────────────────────────────────────────────────────
resource "aws_lb_target_group" "blue" {
  name        = "${var.environment}-blue-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    path                = "/healthy.html"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "${var.environment}-blue-tg"
  }
}

# ─────────────────────────────────────────────────────────────
# Green Target Group (NEW)
# ─────────────────────────────────────────────────────────────
resource "aws_lb_target_group" "green" {
  name        = "${var.environment}-green-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    path                = "/healthy.html"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "${var.environment}-green-tg"
  }
}

# ─────────────────────────────────────────────────────────────
# HTTP →  HTTPS Redirect
# ─────────────────────────────────────────────────────────────
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ─────────────────────────────────────────────────────────────
# HTTPS Listener (Default → BLUE)
# ─────────────────────────────────────────────────────────────
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }
}

# ─────────────────────────────────────────────────────────────
# GREEN Listener Rule (ATTACHES GREEN TO ALB)
# ─────────────────────────────────────────────────────────────
resource "aws_lb_listener_rule" "green_rule" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green.arn
  }

  condition {
    path_pattern {
      values = ["/green/*"]
    }
  }
}
