resource "aws_key_pair" "access_key" {
  key_name   = var.ec2_key_name
  public_key = var.sshkey # This key is provided via TF vars on the command line

  tags = {
    Name      = var.ec2_keypair_tag_name
    CreatedBy = var.createdby_tag
    Owner     = var.owner_tag
    Purpose   = var.purpose_tag
  }
}

locals {
  host_names = [for i in range(var.hosts) : "minio-${i + 1}"]
}

resource "aws_instance" "minio_host" {
  for_each = toset(local.host_names) # Creates a EC2 instance per string provided

  ami                         = var.ec2_ami_image
  instance_type               = var.ec2_instance_type
  key_name                    = aws_key_pair.access_key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.main_vpc_sg.id]
  subnet_id                   = aws_subnet.public.id
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name # Attach Profile To allow AWS CLI commands

  # MinIO EBS volume
  dynamic "ebs_block_device" {
    for_each = var.disks
    content {
      device_name           = "/dev/sd${ebs_block_device.value}"
      volume_size           = var.ebs_volume_size
      delete_on_termination = var.delete_ebs_on_termination
      volume_type           = var.ebs_volume_type
    }
  }  

  # User data script to bootstrap MinIO
  user_data = base64encode(templatefile("${path.module}/setup.sh", {
        node_name           = "${each.key}"
        disks               = join(" ", formatlist("xvd%s", var.disks))
        host_count          = length(local.host_names)
        disk_count          = length(var.disks)
        hosts               = join(" ", local.host_names)
  } ))

  tags = {
    Name      = "${each.key}"
    CreatedBy = var.createdby_tag
    Owner     = var.owner_tag
    Purpose   = var.purpose_tag
    Group     = var.group_tag
  }
}


resource "aws_security_group" "main_vpc_sg" {
  name   = var.aws_security_group_name
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9001
    to_port     = 9001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}