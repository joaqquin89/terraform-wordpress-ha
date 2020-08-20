
module "efs-sg" {
  source       = "../security_groups"
  name         = "efsSecurityGroup"
  description  = "sg allow traffic for to work with efs"
  tags_sg  =  "${var.tags}"
  vpc_id       = "${var.vpc_id}"
  ingress_cidr = var.subnet_sg
  ingress_rules = [
    {
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
    }
  ]
  egress_rules = [
    {
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
    }
  ]
}

// Create EFS for to attach
resource "aws_efs_file_system" "efs-wordpress" {
   creation_token = var.efs_name
   performance_mode = "generalPurpose"
   throughput_mode = "bursting"
   encrypted = "true"
   tags = "${merge(map("Name", format("%s", var.efs_name)),var.tags)}"

 }

resource "aws_efs_mount_target" "efs-mt-wordpress" {
   file_system_id  = "${aws_efs_file_system.efs-wordpress.id}"
   subnet_id = var.subnet_id
   security_groups = [module.efs-sg.return_id_sg]
 }
