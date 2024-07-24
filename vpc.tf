resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = merge(
    local.tag,
    {
      Name    = format("%s VPC", var.application_name)
      Purpose = format("%s Cluster VPC", var.application_name)
    }
  )
}

# Create an Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.tag,
    {
      Name    = format("%s IGW", var.application_name)
      Purpose = format("IGW for %s Cluster", var.application_name)
    }
  )
}

# Create public subnet
resource "aws_subnet" "public" {
  for_each = local.az_map

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, each.key + 1)
  map_public_ip_on_launch = true
  availability_zone       = each.value

  tags = merge(
    local.tag,
    {
      Name    = format("%s Cluster Public Subnet", var.application_name)
      Purpose = format("%s Cluster Public Subnet", var.application_name)
    }
  )
}

# Create private subnet
resource "aws_subnet" "private" {
  for_each = var.make_private ? local.az_map : {}

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, each.key + 10)
  availability_zone = each.value

  tags = merge(
    local.tag,
    {
      Name    = format("%s Cluster Private Subnet", var.application_name)
      Purpose = format("%s Cluster Private Subnet", var.application_name)
    }
  )
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    local.tag,
    {
      Name    = format("%s Cluster Public Route Table", var.application_name)
      Purpose = format("%s Cluster Public Route Table", var.application_name)
    }
  )
}

# Associate Public Subnet with Public Route Table
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public
  route_table_id = aws_route_table.public.id
  subnet_id      = each.value.id
}

# Create a NAT Gateway
resource "aws_eip" "nat" {
  count = var.make_private ? 1 : 0
  domain = "vpc"

  tags = merge(
    local.tag,
    {
      Name = format("%s EIP for NAT Gateway", var.application_name)
    }
  )
}


resource "aws_nat_gateway" "nat" {
  count = var.make_private ? 1 : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    local.tag,
    {
      Name    = format("%s NAT Gateway", var.application_name)
      Purpose = format("%s Cluster NAT Gateway", var.application_name)
    }
  )
}


# Private Route Table
resource "aws_route_table" "private" {
  count = var.make_private ? 1 : 0
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[0].id
  }

  tags = merge(
    local.tag,
    {
      Name    = format("%s Cluster Private Route Table", var.application_name)
      Purpose = format("%s Cluster Private Route Table", var.application_name)
    }
  )
}

# Associate Private Subnet with Private Route Table
resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private
  route_table_id = aws_route_table.private[0].id
  subnet_id      = each.value.id
}
