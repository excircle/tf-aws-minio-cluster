resource "aws_key_pair" "access_key" {
  key_name   = var.ec2_key_name
  public_key = var.sshkey # This key is provided via TF vars on the command line

  tags = merge(
    local.tag,
    {
      Name = format("%s-ec2-key", var.application_name)
      Purpose = format("%s EC2 Key Pair", var.application_name)
    }
  )
}

resource "aws_instance" "minio_host" {
  for_each = toset(local.host_names) # Creates a EC2 instance per string provided

  ami                         = var.ec2_ami_image
  instance_type               = var.ec2_instance_type
  key_name                    = aws_key_pair.access_key.key_name
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.main_vpc_sg.id]
  subnet_id                   = aws_subnet.private.id
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

  tags = merge(
    local.tag,
    {
      Name = "${each.key}"
      Purpose = format("%s Cluster Node", var.application_name)
    }
  )
}


