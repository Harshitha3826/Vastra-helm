# ArgoCD Applications for Vastra

This folder contains ArgoCD Application manifests for GitOps deployment.

## Structure

```
argocd/
├── README.md
├── vastra-dev.yaml          # Dev environment application
├── vastra-main.yaml         # Main/Production environment application
├── vastra-project.yaml      # ArgoCD Project definition
└── repository-secret.yaml   # Git repository credentials (optional)
```

## Applications

### vastra-dev.yaml
- **Namespace:** dev
- **Environment:** Development
- **Auto-sync:** Enabled
- **Self-heal:** Enabled
- **Prune:** Enabled

### vastra-main.yaml
- **Namespace:** main
- **Environment:** Production
- **Auto-sync:** Enabled
- **Self-heal:** Enabled
- **Prune:** Enabled

## Deployment

### Method 1: Apply via kubectl (Recommended for initial setup)

```bash
kubectl apply -f argocd/ -n argocd
```

### Method 2: Apply via ArgoCD CLI

```bash
argocd app create -f argocd/vastra-dev.yaml
argocd app create -f argocd/vastra-main.yaml
```

## Sync Options

Both applications have auto-sync enabled with:
- **Prune:** Removes resources not in Git
- **Self-heal:** Automatically corrects drift
- **CreateNamespace:** Creates namespace if doesn't exist

## Accessing Applications

After deployment, view in ArgoCD UI:
- URL: https://localhost:8080 (or your NodePort)
- Username: admin
- Password: (from `kubectl -n argocd get secret argocd-initial-admin-secret`)

## Repository Connection

If using HTTPS with token, the repository is connected directly in the Application spec.
If using SSH, create a repository secret first (see repository-secret.yaml).


cd /home/ubuntu/Vastra-helm/vastra-deployments

# First, edit database files to change namespace from dev to main
# Or use sed to replace namespace: dev with namespace: main

# Create namespace
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -

# Deploy databases (after editing namespace)
kubectl apply -f databases/ -n dev

# Delete existing gateway if present
kubectl delete gateway vastra-gateway-dev -n dev || true

# Deploy individual services
helm upgrade -i vastra-dev-frontend ./charts/frontend --namespace dev --values values-dev.yaml --wait
helm upgrade -i vastra-dev-user-service ./charts/Vastra-user-service --namespace dev --values values-dev.yaml --wait
helm upgrade -i vastra-dev-product-service ./charts/Vastra-product-service --namespace dev --values values-dev.yaml --wait
helm upgrade -i vastra-dev-order-service ./charts/Vastra-order-service --namespace dev --values values-dev.yaml --wait
helm upgrade -i vastra-dev-gateway ./charts/envoy-gateway --namespace dev --values values-dev.yaml --wait