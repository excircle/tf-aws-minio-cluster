resource "aws_key_pair" "access_key" {
  key_name   = format("%s-%s", var.application_name, var.ec2_key_name)
  public_key = var.sshkey # This key is provided via TF vars on the command line

  tags = merge(
    local.tag,
    {
      Name = format("%s-ec2-key", var.application_name)
      Purpose = format("%s EC2 Key Pair", var.application_name)
    }
  )
}

resource "random_integer" "subnet_selector" {
  for_each = toset(local.host_names)
  min      = 0
  max      = length(var.subnets) - 1
}

resource "aws_instance" "minio_host" {
  for_each = toset(local.host_names) # Creates an EC2 instance per string provided

  ami                         = var.ec2_ami_image
  instance_type               = var.ec2_instance_type
  key_name                    = aws_key_pair.access_key.key_name
  associate_public_ip_address = var.make_private == false ? true : false
  vpc_security_group_ids      = [aws_security_group.main_vpc_sg.id]
  subnet_id = length(var.subnets.private) > 0 ? element([for v in var.subnets.private : v], random_integer.subnet_selector[each.key].result % length(var.subnets.private)) : element([for v in var.subnets.public : v], random_integer.subnet_selector[each.key].result % length(var.subnets.public))

  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name # Attach Profile To allow AWS CLI commands

  root_block_device {
    volume_size = var.ebs_root_volume_size
    volume_type = "gp3"
    delete_on_termination = true
  }

  # User data script to bootstrap MinIO
  user_data = base64encode(templatefile("${path.module}/setup.sh", {
        hosts                 = tostring(join(" ", local.host_names))
        node_name             = "${each.key}"
        disks                 = join(" ", local.disk_names)
        host_count            = tostring(length(local.host_names))
        disk_count            = var.num_disks
        package_manager       = var.package_manager
        minio_binary_arch     = var.minio_binary_arch
        minio_binary_version  = var.minio_binary_version
        minio_flavor          = var.minio_flavor
        minio_license         = var.minio_license
        system_user           = var.system_user
        volume_name           = var.application_name
  } ))

  tags = merge(
    local.tag,
    {
      Name = "${each.key}"
      Purpose = format("%s Cluster Node", var.application_name)
    }
  )
}

# Generate JSON file containing aws_instance.minio_host disk names for first host
resource "local_file" "disk_info" {
  count = var.generate_disk_info == true && var.hosts > 0 ? 1 : 0
  filename = "disk-info.json"
  content  = jsonencode({
    disks     = [for d in aws_instance.minio_host[format("%s-1", var.application_name)].ebs_block_device : d.device_name]
    size      = var.ebs_storage_volume_size
    hostnames = local.host_names
  })
}