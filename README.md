# n8n Hetzner Server Setup

This project contains everything needed to deploy n8n (workflow automation tool) on a Hetzner server with Docker, PostgreSQL, and Traefik reverse proxy with SSL certificates.

## 🏗️ Architecture

- **n8n**: Main workflow automation platform
- **PostgreSQL**: Database for n8n data persistence
- **Traefik**: Reverse proxy with automatic SSL certificates
- **Docker**: Containerization platform

## 📋 Prerequisites

- Hetzner server (VPS or dedicated)
- Domain name with DNS pointing to your server
- SSH access to your server

## 🚀 Quick Start

### 1. Server Setup

Upload and run the setup script on your Hetzner server:

```bash
# Upload the setup script to your server
scp scripts/setup-hetzner.sh user@your-server-ip:~/

# Connect to your server
ssh user@your-server-ip

# Run the setup script
chmod +x ~/setup-hetzner.sh
./setup-hetzner.sh

# Log out and back in for Docker group changes to take effect
exit
ssh user@your-server-ip
```

### 2. Deploy n8n

```bash
# Create n8n directory
mkdir ~/n8n && cd ~/n8n

# Copy configuration files (upload from your local machine)
# Upload docker-compose.yml and .env files to ~/n8n/

# Copy environment template
cp .env.example .env

# Edit configuration
nano .env
```

### 3. Configure Environment

Edit your `.env` file with your specific values:

```bash
# Required changes:
DOMAIN=your-domain.com
WEBHOOK_URL=https://n8n.your-domain.com
N8N_BASIC_AUTH_PASSWORD=your_secure_password
POSTGRES_PASSWORD=your_secure_database_password
ACME_EMAIL=your-email@example.com
```

### 4. Generate Traefik Authentication

```bash
# Install apache2-utils for htpasswd
sudo apt install apache2-utils

# Generate password hash (replace 'admin' and 'password' with your credentials)
echo $(htpasswd -nb admin password) | sed -e s/\\$/\\$\\$/g

# Add the output to your .env file as TRAEFIK_AUTH
```

### 5. Start Services

```bash
# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f n8n
```

## 📁 Project Structure

```
n8n-integrations/
├── docker-compose.yml          # Docker services configuration
├── .env.example               # Environment variables template
├── scripts/
│   └── setup-hetzner.sh      # Server setup script
├── workflows/                 # n8n workflow backups
├── docs/                     # Documentation
└── README.md                 # This file
```

## 🌐 Access Your Services

After deployment:

- **n8n Interface**: `https://n8n.your-domain.com`
- **Traefik Dashboard**: `https://traefik.your-domain.com`

## 🔒 Security Features

- UFW firewall configured (SSH, HTTP, HTTPS only)
- Fail2ban protection against brute force attacks
- SSL certificates via Let's Encrypt
- Basic authentication for n8n and Traefik
- PostgreSQL isolated in Docker network

## 📊 Monitoring & Management

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f n8n
docker-compose logs -f postgres
docker-compose logs -f traefik
```

### Update n8n
```bash
docker-compose pull
docker-compose up -d
```

### Backup Database
```bash
# Create backup
docker-compose exec postgres pg_dump -U n8n_user n8n > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore backup
cat backup_file.sql | docker-compose exec -T postgres psql -U n8n_user -d n8n
```

### Backup n8n Data
```bash
# Backup workflows and settings
docker-compose exec n8n n8n export:workflow --backup --output=/tmp/
docker cp $(docker-compose ps -q n8n):/tmp/ ./backups/
```

## 🔧 Troubleshooting

### Common Issues

1. **SSL Certificate Issues**
   ```bash
   # Check Traefik logs
   docker-compose logs traefik
   
   # Verify domain DNS
   nslookup your-domain.com
   ```

2. **n8n Connection Issues**
   ```bash
   # Check n8n logs
   docker-compose logs n8n
   
   # Verify database connection
   docker-compose exec postgres psql -U n8n_user -d n8n
   ```

3. **Port Already in Use**
   ```bash
   # Check what's using port 80/443
   sudo netstat -tulpn | grep :80
   sudo netstat -tulpn | grep :443
   ```

### Useful Commands

```bash
# Restart all services
docker-compose restart

# Rebuild services
docker-compose up -d --build

# Remove all containers and data (⚠️ DESTRUCTIVE)
docker-compose down -v
```

## 🔗 Integration with Business Central

This setup is designed to work with Microsoft Dynamics 365 Business Central. The `workflows/` directory can contain:

- BC webhook receivers
- Data synchronization workflows  
- Report automation
- Integration snippets

## 📞 Support

For issues with:
- **n8n**: Check [n8n documentation](https://docs.n8n.io/)
- **Hetzner**: Contact Hetzner support
- **This setup**: Create an issue in this repository

## 📄 License

This project is licensed under the MIT License.