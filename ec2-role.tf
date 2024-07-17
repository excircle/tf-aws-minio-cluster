# Assume Role
resource "aws_iam_role" "ec2_cli_role" {
  name = var.aws_iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      },
    ]
  })
  tags = merge(
    local.tag,
    {
      Name = format("%s-ec2-cli-role", var.application_name)
      Purpose = format("%s ec2 cli role", var.application_name)
    }
  )
}

# Grants policy holder auth to use AWS CLI
resource "aws_iam_policy" "describe_instances" {
  name        = var.aws_iam_policy_name
  description = "Allow EC2 instances to run AWS CLI commands"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = "ec2:DescribeInstances",
        Effect   = "Allow",
        Resource = "*"
      },
    ]
  })

  tags = merge(
    local.tag,
    {
      Name = format("%s-iam-policy", var.application_name)
      Purpose = format("%s describe instances iam policy", var.application_name)
    }
  )
}

# Bind 'describe instances' policy to 'ec2_cli_role'
resource "aws_iam_role_policy_attachment" "ec2_describe_instances" {
  role       = aws_iam_role.ec2_cli_role.name
  policy_arn = aws_iam_policy.describe_instances.arn
}

# Bind 'ec2_cli_role' to 'ec2_instance_profile'
# Profile will be bound to EC2 during instance declaration
resource "aws_iam_instance_profile" "ec2_profile" {
  name = var.ec2_instance_profile_name
  role = aws_iam_role.ec2_cli_role.name
  tags = merge(
    local.tag,
    {
      Name = format("%s-ec2-instance-profile", var.application_name)
      Purpose = format("%s ec2 instance profile", var.application_name)
    }
  )
}