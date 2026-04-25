#!/bin/bash

# Cleanup Script for Vastra Applications
# Usage: ./cleanup.sh [environment] [--all]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to cleanup specific environment
cleanup_environment() {
    local env=$1
    print_info "Cleaning up $env environment..."
    
    # Uninstall Helm releases
    helm uninstall vastra-$env -n $env 2>/dev/null || print_warning "vastra-$env release not found"
    helm uninstall vastra-$env-gateway -n $env 2>/dev/null || print_warning "vastra-$env-gateway release not found"
    
    # Delete databases
    kubectl delete -f databases/ -n $env 2>/dev/null || print_warning "Database resources not found in $env"
    
    # Delete PVCs
    kubectl delete pvc --all -n $env 2>/dev/null || print_warning "No PVCs found in $env"
    
    # Delete namespace (optional - comment out if you want to keep namespace)
    read -p "Delete namespace '$env'? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kubectl delete namespace $env 2>/dev/null || print_warning "Namespace $env not found"
    fi
    
    print_success "Cleanup of $env environment completed"
}

# Function to cleanup all environments
cleanup_all() {
    print_info "Cleaning up ALL environments..."
    
    # Cleanup dev
    cleanup_environment "dev"
    echo ""
    
    # Cleanup main
    cleanup_environment "main"
    echo ""
    
    # Cleanup NFS provisioner
    print_info "Cleaning up NFS provisioner..."
    kubectl delete -f nfs-client/ 2>/dev/null || print_warning "NFS client resources not found"
    kubectl delete namespace nfs-provisioner 2>/dev/null || print_warning "NFS provisioner namespace not found"
    
    # Cleanup kgateway
    print_info "Cleaning up Envoy Gateway..."
    helm uninstall kgateway -n kgateway-system 2>/dev/null || print_warning "kgateway not found"
    kubectl delete namespace kgateway-system 2>/dev/null || print_warning "kgateway-system namespace not found"
    
    print_success "Complete cleanup finished!"
}

# Function to show usage
usage() {
    echo "Usage: $0 [environment] [--all]"
    echo ""
    echo "Environments:"
    echo "  dev     - Clean up dev environment only"
    echo "  main    - Clean up main environment only"
    echo "  --all   - Clean up all environments and infrastructure"
    echo ""
    echo "Examples:"
    echo "  $0 dev"
    echo "  $0 main"
    echo "  $0 --all"
}

# Main logic
case $1 in
    dev)
        cleanup_environment "dev"
        ;;
    main)
        cleanup_environment "main"
        ;;
    --all)
        cleanup_all
        ;;
    *)
        usage
        exit 1
        ;;
esac
