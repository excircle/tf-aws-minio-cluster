# #------------------------------------------------------------------------------
# # Backend
# #------------------------------------------------------------------------------
# resource "aws_lb_target_group" "minio_api_lb_target_group" {
#   count                = var.load_balancing_scheme == "NONE" ? 0 : 1
#   name                 = format("%s-api", lower(var.application_name))
#   target_type          = "instance"
#   port                 = var.minio_api_port
#   protocol             = "TCP"
#   vpc_id               = aws_vpc.main.id
#   deregistration_delay = 15
#   tags                 = merge(
#     local.tag,
#     {
#       Name = format("%s-api-target-group", lower(var.application_name))
#       Purpose = format("%s Cluster LB Target Group", var.application_name)
#     }
#   )

#   // TO-DO: Add health check
# }

# resource "aws_lb_listener" "minio_api_lb_listener" {
#   count             = var.load_balancing_scheme == "NONE" ? 0 : 1
#   load_balancer_arn = aws_lb.minio_lb[0].id
#   port              = var.minio_api_port
#   protocol          = "TCP"
#   tags              = merge(
#     local.tag,
#     {
#       Name = format("%s-api-lb-listener", lower(var.application_name))
#       Purpose = format("%s Cluster LB Listener", var.application_name)
#     }
#   )

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.minio_api_lb_target_group[0].arn
#   }
# }

# resource "aws_lb_target_group_attachment" "minio" {
#   for_each          = aws_instance.minio_host
#   target_group_arn  = aws_lb_target_group.minio_console_lb_target_group[0].arn
#   target_id         = each.value.id
#   port              = 9001
# }

# #------------------------------------------------------------------------------
# # Frontend
# #------------------------------------------------------------------------------
# resource "aws_lb" "minio_lb" {
#   count              = var.load_balancing_scheme == "NONE" ? 0 : 1
#   name               = format("%s-load-balancer", lower(var.application_name))
#   internal           = var.load_balancing_scheme == "INTERNAL" ? true : false
#   load_balancer_type = "network"
#   subnets            = [aws_subnet.public.id]
#   tags               = merge(
#     local.tag,
#     {
#       Name = format("%s-cluster-load-balancer", lower(var.application_name))
#       Purpose = format("%s Cluster Load Balancer", var.application_name)
#     }
#   )
# }

# resource "aws_lb_target_group" "minio_console_lb_target_group" {
#   count                = var.load_balancing_scheme == "NONE" ? 0 : 1
#   name                 = format("%s-console-target-group", lower(var.application_name))
#   target_type          = "instance"
#   port                 = var.minio_console_port
#   protocol             = "TCP"
#   vpc_id               = aws_vpc.main.id
#   deregistration_delay = 15
#   tags               = merge(
#     local.tag,
#     {
#       Name = format("%s-console-lb-target-group", lower(var.application_name))
#       Purpose = format("%s Console LB Target Group", var.application_name)
#     }
#   )

#   // TO-DO: Add health check
# }

# resource "aws_lb_listener" "minio_console_lb_listener" {
#   count             = var.load_balancing_scheme == "NONE" ? 0 : 1
#   load_balancer_arn = aws_lb.minio_lb[0].id
#   port              = var.minio_console_port
#   protocol          = "TCP"
#   tags              = merge(
#     local.tag,
#     {
#       Name = format("%s-console-lb-listener", lower(var.application_name))
#       Purpose = format("%s Console LB Listener", var.application_name)
#     }
#   )

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.minio_console_lb_target_group[0].arn
#   }
# }
