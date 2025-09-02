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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root for security reasons"
   exit 1
fi

# Update system packages
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required packages
print_status "Installing required packages..."
sudo apt install -y \
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
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
else
    print_status "Docker is already installed"
fi

# Install Docker Compose
if ! command -v docker-compose &> /dev/null; then
    print_status "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    print_status "Docker Compose is already installed"
fi

# Configure UFW firewall
print_status "Configuring firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

# Configure fail2ban
print_status "Configuring fail2ban..."
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Create n8n directory
N8N_DIR="/home/$USER/n8n"
if [ ! -d "$N8N_DIR" ]; then
    print_status "Creating n8n directory..."
    mkdir -p $N8N_DIR
fi

print_status "Setup completed! Next steps:"
echo "1. Copy your docker-compose.yml and .env files to $N8N_DIR"
echo "2. Configure your .env file with your domain and credentials"
echo "3. Run: cd $N8N_DIR && docker-compose up -d"
echo "4. Point your domain DNS to this server's IP address"

print_warning "Please log out and log back in for Docker group changes to take effect"

echo ""
print_status "Server Information:"
echo "- IP Address: $(curl -s ifconfig.me)"
echo "- OS: $(lsb_release -d | cut -f2)"
echo "- Docker Version: $(docker --version 2>/dev/null || echo 'Not available until re-login')"
echo "- Docker Compose Version: $(docker-compose --version 2>/dev/null || echo 'Not available until re-login')"