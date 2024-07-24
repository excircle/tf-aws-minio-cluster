#------------------------------------------------------------------------------
# Backend
#------------------------------------------------------------------------------
resource "aws_lb" "minio_lb" {
  count              = var.load_balancing_scheme == "NONE" ? 0 : 1
  name               = format("%s-load-balancer", lower(var.application_name))
  internal           = var.load_balancing_scheme == "INTERNAL" ? true : false
  load_balancer_type = "application"
  security_groups = [aws_security_group.bastion_sg.id]
  subnets            = [ for k, v in aws_subnet.public : v.id ]
  tags               = merge(
    local.tag,
    {
      Name = format("%s-cluster-load-balancer", lower(var.application_name))
      Purpose = format("%s Cluster Load Balancer", var.application_name)
    }
  )
}

resource "aws_lb_target_group" "minio_console_lb_target_group" {
  count                = var.load_balancing_scheme == "NONE" ? 0 : 1
  name                 = format("%s-console", lower(var.application_name))
  target_type          = "instance"
  port                 = var.minio_console_port
  protocol             = "HTTP"
  vpc_id               = aws_vpc.main.id
  deregistration_delay = 15
  tags                 = merge(
    local.tag,
    {
      Name = format("%s-console-target-group", lower(var.application_name))
      Purpose = format("%s Cluster LB Target Group", var.application_name)
    }
  )
}

resource "aws_lb_target_group" "minio_api_lb_target_group" {
  count                = var.load_balancing_scheme == "NONE" ? 0 : 1
  name                 = format("%s-api", lower(var.application_name))
  target_type          = "instance"
  port                 = var.minio_api_port
  protocol             = "HTTP"
  vpc_id               = aws_vpc.main.id
  deregistration_delay = 15
  tags                 = merge(
    local.tag,
    {
      Name = format("%s-api-target-group", lower(var.application_name))
      Purpose = format("%s Cluster LB Target Group", var.application_name)
    }
  )
}

resource "aws_lb_listener" "minio_console_lb_listener" {
  count             = var.load_balancing_scheme == "NONE" ? 0 : 1
  load_balancer_arn = aws_lb.minio_lb[0].id
  port              = var.minio_console_port
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.minio_console_lb_target_group[0].arn
  }

  tags              = merge(
    local.tag,
    {
      Name = format("%s-console-lb-listener", lower(var.application_name))
      Purpose = format("%s Cluster LB Listener", var.application_name)
    }
  )
}

resource "aws_lb_listener" "minio_api_lb_listener" {
  count             = var.load_balancing_scheme == "NONE" ? 0 : 1
  load_balancer_arn = aws_lb.minio_lb[0].id
  port              = var.minio_api_port
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.minio_api_lb_target_group[0].arn
  }

  tags              = merge(
    local.tag,
    {
      Name = format("%s-api-lb-listener", lower(var.application_name))
      Purpose = format("%s Cluster LB Listener", var.application_name)
    }
  )
}

resource "aws_lb_target_group_attachment" "minio_console" {
  for_each          = aws_instance.minio_host
  target_group_arn  = aws_lb_target_group.minio_console_lb_target_group[0].arn
  target_id         = each.value.id
  port              = var.minio_console_port
}

resource "aws_lb_target_group_attachment" "minio_api" {
  for_each          = aws_instance.minio_host
  target_group_arn  = aws_lb_target_group.minio_api_lb_target_group[0].arn
  target_id         = each.value.id
  port              = var.minio_api_port
}
