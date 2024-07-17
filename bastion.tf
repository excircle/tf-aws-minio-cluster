
resource "aws_instance" "bastion_host" {
  count = var.bastion_host ? 1 : 0

  ami                         = var.ec2_ami_image
  instance_type               = var.ec2_instance_type
  key_name                    = aws_key_pair.access_key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  subnet_id                   = aws_subnet.public.id
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name # Attach Profile To allow AWS CLI commands

  # Bootstrap commands
  user_data                   = <<EOF
#!/bin/bash
# Update and install packages
apt update -y   
apt install mlocate awscli tree jq tzdata chrony -y

# Set hostname
hostnamectl set-hostname minio-bastion-host

# Setup mc binary
wget https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
mv mc /usr/local/bin
EOF

  tags = merge(
    local.tag,
    {
      Name = format("%s Bastion Host", var.application_name)
      Purpose = format("%s Cluster Node", var.application_name)
    }
  )
}