locals {
  // Universal AWS Tag
  tag = {
    Name      = null
    CreatedBy = var.createdby_tag
    Owner     = var.owner_tag
    Purpose   = null
  }
  // Host names
  host_names = [for i in range(var.hosts) : "xminio-${i + 1}"]
  // Availability Zones
  az = data.aws_availability_zones.available.names
  selected_az = slice(local.az, 0, var.az_count)
  // Map of AZs with index
  az_map = { for idx, az in local.selected_az : idx => az }
}