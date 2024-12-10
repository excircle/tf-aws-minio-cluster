output "local-disks" {
  value       = local.disks
}

output "disk-names" {
  value       = local.disk_names
}


output "subnets" {
  value     = var.subnets
}

output "ec2s" {
  value   = aws_instance.minio_host
}

output "minio_host_info" {
  value = {
    for k, v in aws_instance.minio_host : k => {
      id                 = v.id
      availability_zone  = v.availability_zone
    }
  }
}
