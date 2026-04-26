# Vastra Deployment Guide

## Overview

This guide explains the deployment architecture for the Vastra e-commerce application using ArgoCD and SealedSecrets.

## Architecture

### Structure

```
vastra-deployments/
├── argocd/
│   ├── vastra-project.yaml          # ArgoCD Project
│   ├── vastra-secrets-dev.yaml       # Secrets app for dev
│   ├── vastra-secrets-main.yaml      # Secrets app for main
│   ├── vastra-dev.yaml               # Main app for dev
│   ├── vastra-main.yaml              # Main app for main
│   └── repository-secret.yaml         # Git credentials
├── secrets/
│   ├── dev/                          # SealedSecrets for dev namespace
│   │   ├── users-db-secret.yaml
│   │   ├── products-db-secret.yaml
│   │   ├── orders-db-secret.yaml
│   │   └── jwt-secret.yaml
│   └── main/                         # SealedSecrets for main namespace
│       ├── users-db-secret.yaml
│       ├── products-db-secret.yaml
│       ├── orders-db-secret.yaml
│       └── jwt-secret.yaml
├── charts/                           # Helm charts (no SealedSecrets)
│   ├── Vastra-user-service/
│   ├── Vastra-product-service/
│   ├── Vastra-order-service/
│   ├── frontend/
│   ├── envoy-gateway/
│   └── postgresql/
├── values-dev.yaml                   # Dev environment values
└── values-main.yaml                  # Main environment values
```

### Key Features

1. **Separate Secrets Applications**: SealedSecrets are deployed via dedicated ArgoCD applications (`vastra-secrets-dev`, `vastra-secrets-main`)
2. **Helm Charts Clean**: Helm charts only reference secrets, they don't create them
3. **Automated Sync**: ArgoCD automatically syncs changes from Git
4. **Namespace Isolation**: Each environment has its own namespace (dev, main)

## Deployment Steps

### Prerequisites

- Kubernetes cluster with ArgoCD installed
- SealedSecrets controller installed
- kubectl configured to access your cluster
- Git repository access

### Step 1: Apply ArgoCD Project

```bash
kubectl apply -f vastra-deployments/argocd/vastra-project.yaml
```

### Step 2: Configure Git Repository Secret (if using private repo)

```bash
kubectl apply -f vastra-deployments/argocd/repository-secret.yaml
```

### Step 3: Delete Existing Secrets (Critical!)

Before deploying, delete existing manually created secrets to avoid conflicts:

```bash
# Delete secrets in dev namespace
kubectl delete secret users-db-secret products-db-secret orders-db-secret jwt-secret -n dev

# Delete secrets in main namespace
kubectl delete secret users-db-secret products-db-secret orders-db-secret jwt-secret -n main
```

### Step 4: Apply Secrets Applications (Apply First!)

Secrets must be deployed before the main application:

```bash
# Apply dev secrets
kubectl apply -f vastra-deployments/argocd/vastra-secrets-dev.yaml

# Apply main secrets
kubectl apply -f vastra-deployments/argocd/vastra-secrets-main.yaml
```

### Step 5: Wait for Secrets to Sync

```bash
# Watch secrets applications
kubectl get applications -n argocd -w

# Verify secrets are created
kubectl get secrets -n dev
kubectl get secrets -n main
```

### Step 6: Apply Main Applications

```bash
# Apply dev application
kubectl apply -f vastra-deployments/argocd/vastra-dev.yaml

# Apply main application
kubectl apply -f vastra-deployments/argocd/vastra-main.yaml
```

### Step 7: Verify Deployment

```bash
# Check application status
kubectl get applications -n argocd

# Check pods in dev namespace
kubectl get pods -n dev

# Check pods in main namespace
kubectl get pods -n main

# Check services
kubectl get svc -n dev
kubectl get svc -n main

# Verify secrets are created
kubectl get secrets -n dev
kubectl get secrets -n main
```

## Application Sync Order

**Critical**: Always deploy in this order:

1. `vastra-secrets-dev` (creates secrets in dev namespace)
2. `vastra-secrets-main` (creates secrets in main namespace)
3. `vastra-dev` (deploys app to dev namespace)
4. `vastra-main` (deploys app to main namespace)

## Troubleshooting

### Application Shows "Degraded"

**Cause**: Secrets already exist and are not managed by SealedSecrets

**Solution**:
```bash
kubectl delete secret <secret-name> -n <namespace>
```

### Application Shows "OutOfSync"

**Cause**: Git repository is out of sync with cluster

**Solution**:
```bash
# Sync manually via ArgoCD CLI or UI
argocd app sync <app-name> -n argocd
```

### Secrets Not Created

**Cause**: SealedSecrets controller not running or wrong namespace

**Solution**:
```bash
# Check SealedSecrets controller
kubectl get pods -n kube-system | grep sealed-secrets

# Check SealedSecrets
kubectl get sealedsecrets -n <namespace>
```

### Pods Not Starting

**Cause**: Missing secrets or wrong secret references

**Solution**:
```bash
# Check if secrets exist
kubectl get secrets -n <namespace>

# Check pod logs
kubectl logs <pod-name> -n <namespace>

# Describe pod for events
kubectl describe pod <pod-name> -n <namespace>
```

## Secret Management

### Creating New SealedSecrets

1. Create a temporary secret file:
```bash
cat > temp-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
  namespace: dev
type: Opaque
data:
  KEY: base64-encoded-value
EOF
```

2. Seal the secret:
```bash
kubeseal -f temp-secret.yaml -w sealed-secret.yaml
```

3. Move to appropriate folder:
```bash
mv sealed-secret.yaml vastra-deployments/secrets/dev/
```

4. Commit and push to Git

### Updating Secrets

1. Update the SealedSecret file in `secrets/dev/` or `secrets/main/`
2. Commit and push to Git
3. ArgoCD will automatically sync the changes

## Environment-Specific Values

### Dev Environment (`values-dev.yaml`)
- Lower resource limits
- Debug mode enabled
- Development database settings
- Local/development gateway configuration

### Main Environment (`values-main.yaml`)
- Production resource limits
- Debug mode disabled
- Production database settings
- Production gateway configuration
- HPA enabled
- Security contexts enabled
- Network policies enabled

## ArgoCD Application Details

### vastra-secrets-dev
- **Path**: `vastra-deployments/secrets/dev`
- **Namespace**: `dev`
- **Sync Policy**: Automated (prune, self-heal)
- **Resources**: SealedSecrets only

### vastra-secrets-main
- **Path**: `vastra-deployments/secrets/main`
- **Namespace**: `main`
- **Sync Policy**: Automated (prune, self-heal)
- **Resources**: SealedSecrets only

### vastra-dev
- **Path**: `vastra-deployments`
- **Namespace**: `dev`
- **Values File**: `values-dev.yaml`
- **Sync Policy**: Automated (prune, self-heal)
- **Resources**: Helm charts (Deployments, Services, ConfigMaps, etc.)

### vastra-main
- **Path**: `vastra-deployments`
- **Namespace**: `main`
- **Values File**: `values-main.yaml`
- **Sync Policy**: Automated (prune, self-heal)
- **Resources**: Helm charts (Deployments, Services, ConfigMaps, etc.)

## Cleanup

To remove all resources:

```bash
# Delete ArgoCD applications
kubectl delete application vastra-dev -n argocd
kubectl delete application vastra-main -n argocd
kubectl delete application vastra-secrets-dev -n argocd
kubectl delete application vastra-secrets-main -n argocd

# Delete namespaces (this will delete all resources in the namespace)
kubectl delete namespace dev
kubectl delete namespace main
```

## Best Practices

1. **Always deploy secrets first** - Main applications depend on secrets
2. **Never commit actual secrets** - Only commit SealedSecrets
3. **Use environment-specific values** - Separate dev and main configurations
4. **Monitor ArgoCD sync status** - Ensure applications stay in sync
5. **Test in dev first** - Validate changes in dev before deploying to main
6. **Use GitOps workflow** - All changes should go through Git
