#!/bin/bash

# Quick Deployment Script for Vastra Applications
# Simplified deployment for development and testing

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Quick deploy to dev environment
deploy_dev() {
    print_info "Deploying to dev environment..."
    
    # Create namespace if not exists
    kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy databases
    print_info "Deploying databases..."
    kubectl apply -f databases/ -n dev
    
    # Deploy with Helm
    print_info "Deploying application..."
    helm upgrade -i vastra-dev charts/vastra-app \
        --namespace dev \
        --values values-dev.yaml \
        --wait
    
    # Deploy gateway
    helm upgrade -i vastra-dev-gateway charts/envoy-gateway \
        --namespace dev \
        --values values-dev.yaml \
        --wait
    
    print_success "Dev deployment completed!"
}

# Quick deploy to main environment
deploy_main() {
    print_info "Deploying to main environment..."
    
    # Create namespace if not exists
    kubectl create namespace main --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy databases
    print_info "Deploying databases..."
    kubectl apply -f databases/ -n main
    
    # Deploy with Helm
    print_info "Deploying application..."
    helm upgrade -i vastra-main charts/vastra-app \
        --namespace main \
        --values values-main.yaml \
        --wait
    
    # Deploy gateway
    helm upgrade -i vastra-main-gateway charts/envoy-gateway \
        --namespace main \
        --values values-main.yaml \
        --wait
    
    print_success "Main deployment completed!"
}

# Quick status check
check_status() {
    print_info "Checking status..."
    
    echo ""
    echo "=== Dev Environment ==="
    kubectl get pods -n dev -o wide
    kubectl get svc -n dev
    
    echo ""
    echo "=== Main Environment ==="
    kubectl get pods -n main -o wide
    kubectl get svc -n main
}

# Show usage
usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  dev     - Deploy to dev environment"
    echo "  main    - Deploy to main environment"
    echo "  status  - Check status of both environments"
    echo ""
    echo "Examples:"
    echo "  $0 dev"
    echo "  $0 main"
    echo "  $0 status"
}

# Main logic
case $1 in
    dev)
        deploy_dev
        ;;
    main)
        deploy_main
        ;;
    status)
        check_status
        ;;
    *)
        usage
        exit 1
        ;;
esac
