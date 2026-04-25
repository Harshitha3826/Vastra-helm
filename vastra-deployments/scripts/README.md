# Vastra Deployment Scripts

This directory contains deployment scripts for managing Vastra applications across different environments.

## Scripts Overview

### 1. `deploy.sh` - Comprehensive Deployment Script
Full-featured deployment script with multiple actions and environments.

**Usage:**
```bash
./deploy.sh [environment] [action]
```

**Environments:**
- `dev` - Development environment
- `main` - Production environment

**Actions:**
- `deploy` - Deploy the application (default)
- `upgrade` - Upgrade existing deployment
- `delete` - Delete the deployment
- `status` - Show deployment status

**Examples:**
```bash
# Deploy to dev
./deploy.sh dev deploy

# Upgrade main environment
./deploy.sh main upgrade

# Check dev status
./deploy.sh dev status

# Delete main environment
./deploy.sh main delete
```

### 2. `quick-deploy.sh` - Quick Deployment Script
Simplified script for fast deployments during development.

**Usage:**
```bash
./quick-deploy.sh [command]
```

**Commands:**
- `dev` - Quick deploy to dev environment
- `main` - Quick deploy to main environment
- `status` - Check status of both environments

**Examples:**
```bash
# Quick deploy to dev
./quick-deploy.sh dev

# Quick deploy to main
./quick-deploy.sh main

# Check all status
./quick-deploy.sh status
```

### 3. `cleanup.sh` - Cleanup Script
Script for cleaning up deployments and resources.

**Usage:**
```bash
./cleanup.sh [environment] [--all]
```

**Options:**
- `dev` - Clean up dev environment only
- `main` - Clean up main environment only
- `--all` - Clean up all environments and infrastructure

**Examples:**
```bash
# Clean up dev only
./cleanup.sh dev

# Clean up main only
./cleanup.sh main

# Clean up everything
./cleanup.sh --all
```

## Environment Configuration

### Dev Environment (`values-dev.yaml`)
- 1 replica per service
- Lower resource limits
- HPA disabled
- Development settings
- 1Gi storage
- Debug enabled

### Main Environment (`values-main.yaml`)
- 2+ replicas per service
- Higher resource limits
- HPA enabled with auto-scaling
- Production settings
- 5Gi storage
- Security and monitoring enabled

## Prerequisites

1. **kubectl** installed and configured
2. **helm** installed (version 3.x)
3. **Access to Kubernetes cluster**
4. **NFS server configured** (for persistent storage)

## Getting Started

1. **Make scripts executable:**
   ```bash
   chmod +x scripts/*.sh
   ```

2. **Deploy to dev environment:**
   ```bash
   ./quick-deploy.sh dev
   ```

3. **Check deployment status:**
   ```bash
   ./quick-deploy.sh status
   ```

4. **Deploy to main environment:**
   ```bash
   ./quick-deploy.sh main
   ```

## Directory Structure

```
vastra-deployments/
├── scripts/
│   ├── deploy.sh          # Comprehensive deployment script
│   ├── quick-deploy.sh    # Quick deployment script
│   ├── cleanup.sh         # Cleanup script
│   └── README.md          # This file
├── charts/
│   ├── vastra-app/        # Main application chart
│   └── envoy-gateway/     # Envoy Gateway chart
├── databases/             # Database StatefulSets
├── values-dev.yaml        # Dev environment values
├── values-main.yaml       # Main environment values
└── values.yaml            # Default values file
```

## Common Workflows

### Development Workflow
```bash
# Deploy to dev
./quick-deploy.sh dev

# Make changes to code/config

# Upgrade dev
./deploy.sh dev upgrade

# Check status
./deploy.sh dev status
```

### Production Deployment
```bash
# Test in dev first
./quick-deploy.sh dev

# Deploy to main
./quick-deploy.sh main

# Verify main deployment
./deploy.sh main status
```

### Cleanup
```bash
# Clean up dev environment
./cleanup.sh dev

# Clean up everything (use with caution!)
./cleanup.sh --all
```

## Troubleshooting

### Common Issues

1. **Namespace not found:**
   - Scripts automatically create namespaces
   - Check if you have cluster admin permissions

2. **Helm release not found:**
   - Use `deploy` action instead of `upgrade`
   - Check with `helm list -n <namespace>`

3. **Permission denied:**
   - Make scripts executable: `chmod +x scripts/*.sh`
   - Check kubectl permissions: `kubectl auth can-i create namespace`

4. **NFS mount issues:**
   - Verify NFS server is running
   - Check network connectivity
   - Verify storage class exists

### Getting Help

1. Check script logs for detailed error messages
2. Use `status` action to see current deployment state
3. Verify all prerequisites are met
4. Check Kubernetes events: `kubectl get events -n <namespace>`

## Advanced Usage

### Custom Values Files
You can create custom values files for different scenarios:
```bash
# Create custom values
cp values-dev.yaml values-staging.yaml

# Deploy with custom values
helm upgrade -i vastra-staging charts/vastra-app \
  --namespace staging \
  --values values-staging.yaml
```

### Rolling Updates
The scripts support rolling updates:
```bash
# Perform rolling update
./deploy.sh dev upgrade
```

### Blue-Green Deployments
For production, consider blue-green deployments:
```bash
# Deploy to blue
./quick-deploy.sh main

# Test blue environment

# Switch traffic (manual step)
# Update load balancer/service configuration
```

## Security Considerations

1. **Never commit secrets to version control**
2. **Use different passwords for prod vs dev**
3. **Enable RBAC for production environments**
4. **Regularly rotate secrets and passwords**
5. **Monitor and log all deployment activities**

## Monitoring and Logging

The main environment includes monitoring configurations:
- Prometheus metrics
- Grafana dashboards
- Log aggregation
- Health checks and alerts

Check the monitoring section in `values-main.yaml` for configuration options.
