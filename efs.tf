resource "aws_efs_file_system" "main" {
  creation_token = "${var.project_name}-main"
}

resource "aws_efs_mount_target" "main" {
  count           = 3
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = module.vpc.private_subnets[count.index]
  security_groups = [aws_security_group.efs.id]
}

resource "aws_security_group" "efs" {
  name        = "efs-mnt"
  description = "Allows NFS traffic from instances within the VPC."
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"

    cidr_blocks = [
      var.vpc_cidr
    ]
  }

  egress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"

    cidr_blocks = [
      var.vpc_cidr
    ]
  }
}
