# Arctic Adventures Integration Architecture

## Overview
This document describes how the Business Central (BC), n8n automation platform, and cloud infrastructure work together to provide seamless booking and data integration for Arctic Adventures.

## Architecture Components

### 1. Business Central Project (Local Development)
**Location**: `C:\Users\VeigaMagnusdottir\projects\[bc-project]`
- **Purpose**: Core ERP system for Arctic Adventures
- **Technology**: AL language, Microsoft Dynamics 365
- **Key Features**:
  - Purchase order processing
  - Vendor management
  - Booking confirmations
  - Financial operations

### 2. n8n Integration Platform (Hetzner Server)
**Location**: Hetzner Cloud VPS (IP: 157.180.115.170)
**Access**: http://157.180.115.170:5678
- **Purpose**: Workflow automation and API integration hub
- **Components**:
  - n8n workflow engine (Docker container)
  - PostgreSQL database (stores workflow data)
  - Traefik reverse proxy (handles SSL/routing)
- **Key Features**:
  - Webhook endpoints for BC integration
  - BigQuery data lookups
  - Automated workflow processing

### 3. Integration Repository (Version Control)
**Location**: https://github.com/Arctic-Adventures/n8n-integrations
- **Purpose**: Source control for integration configurations
- **Contents**:
  - Docker configurations
  - n8n workflow definitions (JSON)
  - Setup scripts
  - Environment configurations

## Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Arctic Adventures System                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐         ┌──────────────┐      ┌─────────────┐ │
│  │   Business   │         │     n8n      │      │   Google    │ │
│  │   Central    │ ──API──▶│  Automation  │◀────▶│   BigQuery  │ │
│  │   (Local)    │         │  (Hetzner)   │      │   (Cloud)   │ │
│  └──────────────┘         └──────────────┘      └─────────────┘ │
│         │                        │                      │        │
│         ▼                        ▼                      ▼        │
│  ┌──────────────┐         ┌──────────────┐      ┌─────────────┐ │
│  │   Purchase   │         │   Webhook    │      │   Booking   │ │
│  │    Orders    │         │  Endpoints   │      │    Data     │ │
│  └──────────────┘         └──────────────┘      └─────────────┘ │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Integration Workflow: Booking Lookup Example

1. **Purchase Order Creation (BC)**
   - User creates purchase order in Business Central
   - Enters booking reference and vendor number
   - BC needs department/cost center information

2. **API Request (BC → n8n)**
   - BC sends POST request to n8n webhook
   - Endpoint: `http://157.180.115.170:5678/webhook/booking-lookup`
   - Payload: `{booking_number, vendor_no}`

3. **Data Processing (n8n)**
   - n8n receives webhook request
   - Executes BigQuery lookup
   - Queries: `arctic-data.bc_export.bc_booking_department_lookup`
   - Matches booking across multiple reference fields

4. **Response Handling (n8n → BC)**
   - Returns structured JSON response
   - Success: `{status, department, booking_number, supplier_name, bokun_url}`
   - Not found: `{status: "not_found", message}`

5. **BC Updates**
   - Receives department information
   - Updates purchase order with cost center
   - Links to Bokun booking system via URL

## Infrastructure Details

### Hetzner Server Configuration
- **OS**: Ubuntu 24.04.3 LTS
- **Docker**: v28.3.3
- **Docker Compose**: v2.39.2
- **Security**:
  - UFW firewall (ports 80, 443, 5678, SSH)
  - Fail2ban for brute force protection
  - Basic authentication on n8n interface

### Network Security
- **Firewall Rules**:
  - SSH: Restricted access
  - HTTP/HTTPS: Public (80/443)
  - n8n: Port 5678 (HTTP only, no SSL currently)
- **Authentication**:
  - n8n: Basic auth (admin/password)
  - BigQuery: Service account credentials
  - BC: Internal network/VPN

### Data Storage
- **n8n PostgreSQL**: Workflow definitions, execution logs, credentials
- **BigQuery**: Master booking data, department lookups
- **BC Database**: Transactional data, purchase orders, vendor records

## Development & Deployment Process

### Local Development
1. Develop BC extensions locally in VS Code
2. Test API integrations against n8n endpoints
3. Update workflow definitions in n8n web interface

### Workflow Updates
1. Export workflows from n8n interface
2. Save to `n8n-integrations/workflows/`
3. Commit and push to GitHub
4. Version control maintains workflow history

### Server Maintenance
1. SSH access: `ssh root@157.180.115.170`
2. Docker management: `/root/n8n/`
3. Logs: `docker-compose logs -f n8n`
4. Updates: `docker-compose pull && docker-compose up -d`

## Key Integration Points

### BC ↔ n8n
- **Webhook endpoints** for real-time processing
- **RESTful API** communication
- **JSON** data format

### n8n ↔ BigQuery
- **Service account** authentication
- **Parameterized SQL** queries
- **Structured data** returns

### Benefits of This Architecture
1. **Separation of Concerns**: BC handles business logic, n8n handles integrations
2. **Scalability**: Cloud-based n8n can handle increased load
3. **Flexibility**: Workflows can be modified without BC code changes
4. **Monitoring**: n8n provides execution logs and debugging
5. **Version Control**: All configurations tracked in Git

## Future Enhancements
- SSL certificates for secure HTTPS (pending DNS setup)
- Additional workflow automations
- Email notifications via SMTP
- Scheduled data synchronization
- Extended BigQuery integrations

## Support & Access

### Development Team
- **BC Development**: Local development environment
- **n8n Access**: http://157.180.115.170:5678
- **Repository**: https://github.com/Arctic-Adventures/n8n-integrations

### Credentials Management
- Stored in `/root/n8n/.env` on server
- Google service account keys in n8n credentials
- BC API keys configured per environment

---

*This architecture enables Arctic Adventures to maintain a robust, scalable integration between their Business Central ERP and external booking systems, providing real-time data lookups and automated workflow processing.*