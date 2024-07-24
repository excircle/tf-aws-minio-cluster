#------------------------------------------------------------------------------
# Private Cluster
#------------------------------------------------------------------------------

////////////////////
// Security Group //
////////////////////

resource "aws_security_group" "main_vpc_sg" {
  name   = var.aws_security_group_name
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.tag,
    {
      Name = format("%s Security Group", var.application_name)
      Purpose = format("Security Group For %s Cluster", var.application_name)
    }
  )
}

////////////////////
// Security Rules //
////////////////////

// INGRESS
resource "aws_security_group_rule" "allow_bastion_to_ssh_minio_cluster" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.main_vpc_sg.id
  source_security_group_id = aws_security_group.bastion_sg.id
}

resource "aws_security_group_rule" "allow_bastion_api_coms_to_minio_cluster" {
  type                     = "ingress"
  from_port                = var.minio_api_port
  to_port                  = var.minio_api_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.main_vpc_sg.id
  source_security_group_id = aws_security_group.bastion_sg.id
}

resource "aws_security_group_rule" "allow_bastion_console_coms_to_minio_cluster" {
  type                     = "ingress"
  from_port                = var.minio_console_port
  to_port                  = var.minio_console_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.main_vpc_sg.id
  source_security_group_id = aws_security_group.bastion_sg.id
}

resource "aws_security_group_rule" "minio_cluster_ingress_coms" {
  for_each = aws_subnet.private

  type                     = "ingress"
  from_port                = var.minio_api_port
  to_port                  = var.minio_console_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.main_vpc_sg.id
  cidr_blocks              = [ each.value.cidr_block ]
}

resource "aws_security_group_rule" "minio_cluster_ingress_public_coms" {
  count = var.make_private == false ? 1 : 0

  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = -1
  security_group_id        = aws_security_group.main_vpc_sg.id
  cidr_blocks              = [ "0.0.0.0/0" ]
}

// EGRESS
resource "aws_security_group_rule" "minio_cluster_egress_coms" {
  for_each = aws_subnet.private
  
  type                     = "egress"
  from_port                = var.minio_api_port
  to_port                  = var.minio_console_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.main_vpc_sg.id
  cidr_blocks              = [ each.value.cidr_block ]
}

resource "aws_security_group_rule" "allow_global_cluster_egress" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.main_vpc_sg.id
  cidr_blocks              = [ "0.0.0.0/0" ]
}

#------------------------------------------------------------------------------
# Public Hosts
#------------------------------------------------------------------------------

////////////////////
// Security Group //
////////////////////

resource "aws_security_group" "bastion_sg" {
  name   = "bastion-security-group"
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.tag,
    {
      Name = format("%s Security Group", var.application_name)
      Purpose = format("Security Group For %s Cluster", var.application_name)
    }
  )
}

////////////////////
// Security Rules //
////////////////////

resource "aws_security_group_rule" "allow_ssh_to_bastion" {
    type                     = "ingress"
    from_port                = 22
    to_port                  = 22
    protocol                 = "tcp"
    security_group_id        = aws_security_group.bastion_sg.id
    cidr_blocks              = [ "0.0.0.0/0" ]
}

resource "aws_security_group_rule" "allow_global_egress_bastion" {
    type                     = "egress"
    from_port                = 0
    to_port                  = 0
    protocol                 = "-1"
    security_group_id        = aws_security_group.bastion_sg.id
    cidr_blocks              = [ "0.0.0.0/0" ]
}

resource "aws_security_group_rule" "allow_global_api_coms_to_bastion_sg" {
  type                     = "ingress"
  from_port                = var.minio_api_port # 9000
  to_port                  = var.minio_api_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.bastion_sg.id
  cidr_blocks              = [ "0.0.0.0/0" ]
}

resource "aws_security_group_rule" "allow_global_console_coms_to_bastion_sg" {
  type                     = "ingress"
  from_port                = var.minio_console_port # 9001
  to_port                  = var.minio_console_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.bastion_sg.id
  cidr_blocks              = [ "0.0.0.0/0" ]
}