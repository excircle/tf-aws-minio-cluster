#------------------------------------------------------------------------------
# Private Cluster
#------------------------------------------------------------------------------

////////////////////
// Security Group //
////////////////////

resource "aws_security_group" "main_vpc_sg" {
  name   = var.aws_security_group_name
  vpc_id = var.vpc_id

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

resource "aws_security_group_rule" "allow_minio_api_ingress" {
  type                     = "ingress"
  from_port                = var.minio_api_port
  to_port                  = var.minio_api_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.main_vpc_sg.id
  cidr_blocks              = [ "0.0.0.0/0" ]
}

resource "aws_security_group_rule" "allow_minio_console_ingress" {
  type                     = "ingress"
  from_port                = var.minio_console_port
  to_port                  = var.minio_console_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.main_vpc_sg.id
  cidr_blocks              = [ "0.0.0.0/0" ]
}

resource "aws_security_group_rule" "allow_aistor2" {
  type                     = "ingress"
  from_port                = 7899
  to_port                  = 7899
  protocol                 = "tcp"
  security_group_id        = aws_security_group.main_vpc_sg.id
  cidr_blocks              = [ "0.0.0.0/0" ]
}

resource "aws_security_group_rule" "allow_aistor3" {
  type                     = "ingress"
  from_port                = 30080
  to_port                  = 30096
  protocol                 = "tcp"
  security_group_id        = aws_security_group.main_vpc_sg.id
  cidr_blocks              = [ "0.0.0.0/0" ]
}

resource "aws_security_group_rule" "allow_aistor4" {
  type                     = "ingress"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.main_vpc_sg.id
  cidr_blocks              = [ "0.0.0.0/0" ]
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
  vpc_id = var.vpc_id

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