variable "application_name" {
  description = "Application Name"
  type = string
}

variable "createdby_tag" {
  description = "Tag for created by"
  type = string
  default = "Terraform"
}

variable "owner_tag" {
  description = "Tag for owner"
  type = string
  default = "Alexander Kalaj"
}

variable "hosts" {
  description = "Number of hosts to create"
  type = number
  default = 2
}

variable "ec2_key_name" {
  description = "EC2 Key Pair Name"
  type = string
  default = "minio-key"
}

variable "sshkey" {
  description = "SSH key to use with EC2 host"
  type        = string
}

variable "ec2_ami_image" {
  description = "EC2 AMI Image"
  type = string
}

variable "ec2_instance_type" {
  description = "AWS EC2 Instance Type"
  type = string
}

variable "make_private" {
  description = "Make the cluster private"
  type = bool
  default = false
}

variable "aws_iam_role_name" {
  description = "AWS IAM Role Name"
  type = string
  default = "ec2_cli_role"
}

variable "aws_iam_policy_name" {
  description = "AWS IAM Policy Name"
  type = string
  default = "CLI-Policy"
}

variable "ec2_instance_profile_name" {
  description = "EC2 Instance Profile Name"
  type = string
  default = "ec2_instance_profile"
}

variable "ebs_root_volume_size" {
  description = "Root Block Device Size"
  type = number
}

variable "ebs_storage_volume_size" {
  description = "Root Block Device Size"
  type = number
}

variable "minio_license" {
  description = "MinIO License File"
  type = string
  default = ""
}

variable "minio_binary_version" {
  description = "MinIO Binary Version (e.g., 'minio.RELEASE.2025-10-17T06-17-41Z' or 'latest')"
  type = string
  default = "latest"
}

variable "minio_flavor" {
  description = "MinIO Flavor: 'aistor' or 'server'"
  type = string
  default = "aistor"
}

variable "minio_binary_arch" {
  description = "MinIO Binary Architecture"
  type = string
  default = "linux-amd64"
}

variable "minio_console_port" {
  description = "MinIO Console Port"
  type = number
  default = 9001
}

variable "minio_api_port" {
  description = "MinIO API Port"
  type = number
  default = 9000
}

variable "num_disks" {
  description = "Number of disks to attach"
  type = number
  default = 1
}

variable "vpc_id" {
  description = "VPC ID"
  type = string
}

variable "az_count" {
  description = "Number of AZs to use"
  type = number
}

variable "subnets" {
  description = "Subnets"
  type = object({
    private = list(string)
    public  = list(string)
  })
}

variable "load_balancing_scheme" {
  description = "Load Balancer Scheme"
  type = string
  default = "NONE"
}

variable "aws_security_group_name" {
  description = "AWS Security Group Name"
  type = string
  default = "minio-sg"
}

variable "bastion_host" {
  description = "Create Bastion Host"
  type = bool
  default = false
}

variable "package_manager" {
  description = "Package manager for provisioning"
  type        = string
}

variable "system_user" {
  description = "System user for Linux provisioning"
  type        = string
}

variable "generate_disk_info" {
  description = "Generate disk_info.json file"
  type = bool
  default = false
}