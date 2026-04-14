# EFS FILE SYSTEM
resource "aws_efs_file_system" "wordpress" {
  creation_token   = "${var.environment}-wordpress-efs"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true
  lifecycle_policy { transition_to_ia = "AFTER_30_DAYS" }
  tags = { Name = "${var.environment}-wordpress-efs" }
}

resource "aws_efs_mount_target" "wordpress" {
  count           = 2
  file_system_id  = aws_efs_file_system.wordpress.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs.id]
}
