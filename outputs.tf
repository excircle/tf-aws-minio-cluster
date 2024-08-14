// Output public subnets
output "public_subnets" {
  value = aws_subnet.public
}

// Output bastion security group
output "bastion_security_group" {
  value = aws_security_group.bastion_sg
}