#!/bin/bash

# Function to configure netplan
configure_netplan() {
  echo "Configuring netplan..."
  NETPLAN_CONFIG="/etc/netplan/00-installer-config.yaml"
  if grep -q "192.168.16.21/24" "$NETPLAN_CONFIG"; then
    echo "Netplan already configured."
  else
    sudo sed -i '/^      addresses:/a \      - 192.168.16.21/24' "$NETPLAN_CONFIG"
    sudo netplan apply
    echo "Netplan configured."
  fi
}

# Function to update /etc/hosts
update_hosts_file() {
  echo "Updating /etc/hosts..."
  HOSTS_FILE="/etc/hosts"
  if grep -q "192.168.16.21 server1" "$HOSTS_FILE"; then
    echo "/etc/hosts already updated."
  else
    sudo sed -i '/server1$/d' "$HOSTS_FILE"
    echo "192.168.16.21 server1" | sudo tee -a "$HOSTS_FILE"
    echo "/etc/hosts updated."
  fi
}

# Function to install required software
install_software() {
  echo "Installing apache2 and squid..."
  sudo apt update
  sudo apt install -y apache2 squid
  echo "apache2 and squid installed."
}

# Function to configure UFW firewall
configure_firewall() {
  echo "Configuring firewall..."
  sudo ufw reset
  sudo ufw allow from 192.168.16.0/24 to any port 22
  sudo ufw allow http
  sudo ufw allow 3128
  sudo ufw --force enable
  echo "Firewall configured."
}

# Function to create user accounts
create_user_accounts() {
  echo "Creating user accounts..."
  USERS=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
  SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"

  for user in "${USERS[@]}"; do
    if id "$user" &>/dev/null; then
      echo "User $user already exists."
    else
      sudo adduser --home "/home/$user" --shell /bin/bash --disabled-password --gecos "" "$user"
      echo "User $user created."
    fi

    sudo mkdir -p "/home/$user/.ssh"
    sudo ssh-keygen -t rsa -b 2048 -f "/home/$user/.ssh/id_rsa" -N ""
    sudo ssh-keygen -t ed25519 -f "/home/$user/.ssh/id_ed25519" -N ""
    sudo touch "/home/$user/.ssh/authorized_keys"

    RSA_PUB_KEY=$(cat "/home/$user/.ssh/id_rsa.pub")
    ED25519_PUB_KEY=$(cat "/home/$user/.ssh/id_ed25519.pub")
    echo "$RSA_PUB_KEY" | sudo tee -a "/home/$user/.ssh/authorized_keys"
    echo "$ED25519_PUB_KEY" | sudo tee -a "/home/$user/.ssh/authorized_keys"

    sudo chown -R "$user:$user" "/home/$user/.ssh"
  done

  sudo usermod -aG sudo dennis
  echo "$SSH_KEY" | sudo tee -a "/home/dennis/.ssh/authorized_keys"

  echo "User accounts created."
}

# Main function to run all tasks
main() {
  configure_netplan
  update_hosts_file
  install_software
  configure_firewall
  create_user_accounts
  echo "Configuration complete."
}

# Execute the main function
main
