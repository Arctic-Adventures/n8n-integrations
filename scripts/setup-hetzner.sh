#!/bin/bash

# n8n Hetzner Server Setup Script
# This script sets up n8n with Docker on a Hetzner server

set -e

echo "🚀 Starting n8n setup on Hetzner server..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root and adapt accordingly
if [[ $EUID -eq 0 ]]; then
   print_warning "Running as root - will skip sudo commands"
   SUDO_CMD=""
   N8N_DIR="/root/n8n"
else
   SUDO_CMD="sudo"
   N8N_DIR="/home/$USER/n8n"
fi

# Update system packages
print_status "Updating system packages..."
$SUDO_CMD apt update && $SUDO_CMD apt upgrade -y

# Install required packages
print_status "Installing required packages..."
$SUDO_CMD apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    htop \
    ufw \
    fail2ban

# Install Docker
if ! command -v docker &> /dev/null; then
    print_status "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    $SUDO_CMD sh get-docker.sh
    if [[ $EUID -ne 0 ]]; then
        $SUDO_CMD usermod -aG docker $USER
    fi
    rm get-docker.sh
else
    print_status "Docker is already installed"
fi

# Install Docker Compose
if ! command -v docker-compose &> /dev/null; then
    print_status "Installing Docker Compose..."
    $SUDO_CMD curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    $SUDO_CMD chmod +x /usr/local/bin/docker-compose
else
    print_status "Docker Compose is already installed"
fi

# Configure UFW firewall
print_status "Configuring firewall..."
$SUDO_CMD ufw default deny incoming
$SUDO_CMD ufw default allow outgoing
$SUDO_CMD ufw allow ssh
$SUDO_CMD ufw allow 80/tcp
$SUDO_CMD ufw allow 443/tcp
$SUDO_CMD ufw --force enable

# Configure fail2ban
print_status "Configuring fail2ban..."
$SUDO_CMD systemctl enable fail2ban
$SUDO_CMD systemctl start fail2ban

# Create n8n directory
if [ ! -d "$N8N_DIR" ]; then
    print_status "Creating n8n directory..."
    mkdir -p $N8N_DIR
fi

print_status "Setup completed! Next steps:"
echo "1. Copy your docker-compose.yml and .env files to $N8N_DIR"
echo "2. Configure your .env file with your domain and credentials"
echo "3. Run: cd $N8N_DIR && docker-compose up -d"
echo "4. Point your domain DNS to this server's IP address"

if [[ $EUID -ne 0 ]]; then
    print_warning "Please log out and log back in for Docker group changes to take effect"
fi

echo ""
print_status "Server Information:"
echo "- IP Address: $(curl -s ifconfig.me)"
echo "- OS: $(lsb_release -d | cut -f2)"
echo "- Docker Version: $(docker --version 2>/dev/null || echo 'Not available until re-login')"
echo "- Docker Compose Version: $(docker-compose --version 2>/dev/null || echo 'Not available until re-login')"