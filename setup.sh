#!/bin/bash

install_minio_dependencies() {
  local attempt=0
  local max_attempts=3
  local success=false

  while [[ $attempt -lt $max_attempts ]]; do
    echo "Attempting to install MinIO Dependencies (Attempt: $((attempt + 1)))..."
    sudo apt update && sudo apt install awscli tree jq tzdata chrony -y

    if [[ $? -eq 0 ]]; then
      success=true
      touch /tmp/minio_dependencies_installed
      break
    else
      echo "Installation failed. Retrying..."
      attempt=$((attempt + 1))
      sleep 10
    fi
  done

  if [[ $success == false ]]; then
    echo "Installation of MinIO Dependencies failed after $max_attempts attempts."
    exit 1
  fi
}

minio_installation() {
  # Set the timezone to America/Los_Angeles
  echo "Setting timezone to America/Los_Angeles..."
  sudo timedatectl set-timezone America/Los_Angeles

  # Enable and start chrony service
  echo "Enabling and starting chrony service..."
  sudo systemctl enable chrony
  sudo systemctl start chrony

  # Verify the time and timezone settings
  echo "Verifying the time and timezone settings..."
  timedatectl

  # Check the status of chrony service
  echo "Checking the status of chrony service..."
  sudo chronyc tracking

  # Import Variables From Terraform
  host_count=${host_count}
  disk_count=${disk_count}
  node_name=$(echo ${node_name} | sed 's|[0-9]||g')
  hosts=${hosts}
  disks=${disks}
  volume_name=${volume_name}

  # Setup Hostname
  sudo hostnamectl set-hostname ${node_name}

  # Download MinIO Server Binary
  wget https://dl.min.io/server/minio/release/linux-amd64/minio

  # Make executable
  chmod +x minio

  # Move into /usr/local/bin
  sudo mv minio /usr/local/bin/

  # Download MinIO Command Line Client
  wget https://dl.min.io/client/mc/release/linux-amd64/mc

  # Make Executable
  chmod +x mc

  # Add to usr local
  sudo mv mc /usr/local/bin

  # Create minio-user group
  sudo groupadd -r minio-user

  # Create minio-user user
  sudo useradd -m -d /home/minio-user -r -g minio-user minio-user

  # Until loop that waits for all xvd disks to be attached
  echo "Starting for loop"
  echo $disks
  for disk in ${disks}; do
    name=$(echo $disk | sed "s|\/| |g" | awk {'print $NF'})
    while [[ $(lsblk | grep $name | wc -l) == "0" ]]; do
      echo "$(date) - Disk $disk not found...waiting..."
      sleep 5
    done;
    echo "$(date) - Found $disk"
  done;
  echo "For loop completed"


  # Establish Disks
  idx=1
  for disk in ${disks}; do
    sudo mkfs.xfs /dev/$disk
    sudo mkdir -p /mnt/data$idx
    sudo mount /dev/$disk /mnt/data$idx
    sudo chown -R minio-user:minio-user /mnt/data$idx  sudo chown -R minio-user:minio-user /mnt/data$idx
    echo "/dev/$disk /mnt/data$idx xfs defaults,nofail 0 2" | sudo tee -a /etc/fstab
    ((idx++))
  done

# Create MinIO Defaults File
sudo tee /etc/default/minio > /dev/null << EOF
# MINIO_ROOT_USER and MINIO_ROOT_PASSWORD sets the root account for the MinIO server.
# This user has unrestricted permissions to perform S3 and administrative API operations on any resource in the deployment.
# Omit to use the default values 'minioadmin:minioadmin'.
# MinIO recommends setting non-default values as a best practice, regardless of environment

MINIO_ROOT_USER=miniominio
MINIO_ROOT_PASSWORD=miniominio

# MINIO_VOLUMES sets the storage volume or path to use for the MinIO server.

MINIO_VOLUMES="http://$${volume_name}-{1...$${host_count}}:9000/mnt/data{1...$${disk_count}}/minio"

# MINIO_OPTS sets any additional commandline options to pass to the MinIO server.
# For example, '--console-address :9001' sets the MinIO Console listen port
MINIO_OPTS="--address 0.0.0.0:9000 --console-address 0.0.0.0:9001"

# MINIO_SERVER_URL sets the hostname of the local machine for use with the MinIO Server
# MinIO assumes your network control plane can correctly resolve this hostname to the local machine

# Uncomment the following line and replace the value with the correct hostname for the local machine and port for the MinIO server (9000 by default).

MINIO_SERVER_URL="http://0.0.0.0:9000"
EOF

sudo tee /usr/lib/systemd/system/minio.service > /dev/null << 'EOF'
[Unit]
Description=MinIO
Documentation=https://docs.min.io
Wants=network-online.target
After=network-online.target
AssertFileIsExecutable=/usr/local/bin/minio
AssertFileNotEmpty=/etc/default/minio

[Service]
Type=notify
WorkingDirectory=/usr/local/

User=minio-user
Group=minio-user
ProtectProc=invisible

EnvironmentFile=/etc/default/minio
ExecStartPre=/bin/bash -c "if [ -z \"$${MINIO_VOLUMES}\" ]; then echo 'Variable MINIO_VOLUMES not set in /etc/default/minio'; exit 1; fi"
ExecStart=/usr/local/bin/minio server $MINIO_OPTS $MINIO_VOLUMES

# Let systemd restart this service always
Restart=always

# Specifies the maximum file descriptor number that can be opened by this process
LimitNOFILE=1048576

# Specifies the maximum number of threads this process can create
TasksMax=infinity

# Disable timeout logic and wait until process is stopped
TimeoutSec=infinity

SendSIGKILL=no

[Install]
WantedBy=multi-user.target
EOF

  # Update /etc/hosts file with private ips
  for host in ${hosts}; do
    REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
    PRIVATE_IP=$(aws ec2 describe-instances   --region $REGION   --filters "Name=tag:Name,Values=$host"   --query 'Reservations[*].Instances[*].PrivateIpAddress'   --output text)
    echo -e "$PRIVATE_IP $host" | sudo tee -a /etc/hosts
  done

  # Enable and start minio service
  sudo systemctl enable minio
  sudo systemctl start minio
}

############
### MAIN ###
############

main() {
  install_minio_dependencies
  # If /tmp/minio_dependencies_installed exists, then execute the minio_installation function
  if [[ -f /tmp/minio_dependencies_installed ]]; then
    minio_installation
  else
    echo "MinIO Dependencies not installed. Exiting..."
    exit 1
  fi
}

main