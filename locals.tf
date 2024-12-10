locals {
  // Universal AWS Tag
  tag = {
    Name      = null
    CreatedBy = var.createdby_tag
    Owner     = var.owner_tag
    Purpose   = null
  }
  // Host names
  host_names = [for v in range(1, var.hosts+1): "${var.application_name}-${v}"]

  // Disks
  disks = [
    "f",
    "g",
    "h",
    "i",
    "j",
    "k",
    "l",
    "m",
    "n",
    "o",
    "p",
    "q",
    "r",
    "s",
    "t",
    "u",
    "v",
    "w",
    "x",
    "y",
    "z"
  ]

  disk_names = [ for d in toset(slice(local.disks, 0, var.num_disks)) : format("xvd%s", d) ]

  ebs_volumes = flatten([
    for host_key, host_info in aws_instance.minio_host : [
      for disk in local.disk_names : {
        id                 = host_info.id
        availability_zone  = host_info.availability_zone
        disk_name          = disk
        unique_key         = format("%s__%s__%s", host_info.id, host_info.availability_zone, disk)
      }
    ]
  ])

}

