resource "aws_security_group" "alb" {
  name        = "${var.environment}-sg-alb"
  description = "Allow HTTP and HTTPS from internet"
  vpc_id      = aws_vpc.main.id
  ingress { from_port = 80;   to_port = 80;   protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"] }
  ingress { from_port = 443;  to_port = 443;  protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"] }
  egress  { from_port = 0;    to_port = 0;    protocol = "-1";  cidr_blocks = ["0.0.0.0/0"] }
  tags = { Name = "${var.environment}-sg-alb" }
}

resource "aws_security_group" "app" {
  name        = "${var.environment}-sg-app"
  description = "Allow HTTP from ALB only"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
  tags = { Name = "${var.environment}-sg-app" }
}

resource "aws_security_group" "db" {
  name        = "${var.environment}-sg-db"
  description = "Allow MySQL from EC2 only"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
  tags = { Name = "${var.environment}-sg-db" }
}

resource "aws_security_group" "efs" {
  name        = "${var.environment}-sg-efs"
  description = "Allow NFS from EC2 only"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
  tags = { Name = "${var.environment}-sg-efs" }
}
