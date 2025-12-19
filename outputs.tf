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

output "ebs_storage_volume_size" {
  value = var.ebs_storage_volume_size
}

output "minio_license_length" {
  description = "Length of the MinIO license string (for validation)"
  value       = length(var.minio_license)
}
