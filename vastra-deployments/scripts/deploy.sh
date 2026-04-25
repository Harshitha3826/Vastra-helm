#!/bin/bash

# Vastra Application Deployment Script
# Usage: ./deploy.sh [environment] [action]
# Environments: dev, main
# Actions: deploy, upgrade, delete, status

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT=""
ACTION="deploy"
NAMESPACE=""
VALUES_FILE=""
RELEASE_NAME=""

# Function to print colored output
print_status() {
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

# Function to show usage
usage() {
    echo "Usage: $0 [environment] [action]"
    echo ""
    echo "Environments:"
    echo "  dev     - Development environment"
    echo "  main    - Production environment"
    echo ""
    echo "Actions:"
    echo "  deploy  - Deploy the application (default)"
    echo "  upgrade - Upgrade existing deployment"
    echo "  delete  - Delete the deployment"
    echo "  status  - Show deployment status"
    echo ""
    echo "Examples:"
    echo "  $0 dev deploy"
    echo "  $0 main upgrade"
    echo "  $0 dev status"
    echo "  $0 main delete"
}

# Function to validate environment
validate_environment() {
    case $ENVIRONMENT in
        dev|main)
            ;;
        *)
            print_error "Invalid environment: $ENVIRONMENT"
            usage
            exit 1
            ;;
    esac
}

# Function to set environment-specific variables
set_environment_vars() {
    case $ENVIRONMENT in
        dev)
            NAMESPACE="dev"
            VALUES_FILE="values-dev.yaml"
            RELEASE_NAME="vastra-dev"
            ;;
        main)
            NAMESPACE="main"
            VALUES_FILE="values-main.yaml"
            RELEASE_NAME="vastra-main"
            ;;
    esac
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Check if helm is available
    if ! command -v helm &> /dev/null; then
        print_error "helm is not installed or not in PATH"
        exit 1
    fi
    
    # Check if values file exists
    if [ ! -f "$VALUES_FILE" ]; then
        print_error "Values file not found: $VALUES_FILE"
        exit 1
    fi
    
    # Check if charts directory exists
    if [ ! -d "charts" ]; then
        print_error "Charts directory not found"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to create namespace
create_namespace() {
    print_status "Creating namespace: $NAMESPACE"
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
}

# Function to deploy application
deploy_application() {
    print_status "Deploying $RELEASE_NAME to $NAMESPACE namespace..."
    
    create_namespace
    
    # Deploy databases first
    print_status "Deploying databases..."
    kubectl apply -f databases/ -n $NAMESPACE
    
    # Deploy gateway
    print_status "Deploying gateway..."
    helm upgrade -i $RELEASE_NAME-gateway charts/envoy-gateway \
        --namespace $NAMESPACE \
        --values $VALUES_FILE \
        --wait \
        --timeout 10m
    
    # Deploy main application
    print_status "Deploying application services..."
    helm upgrade -i $RELEASE_NAME charts/vastra-app \
        --namespace $NAMESPACE \
        --values $VALUES_FILE \
        --wait \
        --timeout 10m
    
    print_success "Deployment completed successfully"
}

# Function to upgrade application
upgrade_application() {
    print_status "Upgrading $RELEASE_NAME in $NAMESPACE namespace..."
    
    # Upgrade gateway
    print_status "Upgrading gateway..."
    helm upgrade $RELEASE_NAME-gateway charts/envoy-gateway \
        --namespace $NAMESPACE \
        --values $VALUES_FILE \
        --wait \
        --timeout 10m
    
    # Upgrade main application
    print_status "Upgrading application services..."
    helm upgrade $RELEASE_NAME charts/vastra-app \
        --namespace $NAMESPACE \
        --values $VALUES_FILE \
        --wait \
        --timeout 10m
    
    print_success "Upgrade completed successfully"
}

# Function to delete application
delete_application() {
    print_status "Deleting $RELEASE_NAME from $NAMESPACE namespace..."
    
    # Delete main application
    helm uninstall $RELEASE_NAME -n $NAMESPACE || true
    
    # Delete gateway
    helm uninstall $RELEASE_NAME-gateway -n $NAMESPACE || true
    
    # Delete databases
    kubectl delete -f databases/ -n $NAMESPACE || true
    
    # Delete namespace (optional - uncomment if you want to delete the entire namespace)
    # kubectl delete namespace $NAMESPACE || true
    
    print_success "Deletion completed successfully"
}

# Function to show status
show_status() {
    print_status "Showing status for $ENVIRONMENT environment..."
    
    echo ""
    echo "=== Namespace: $NAMESPACE ==="
    kubectl get namespace $NAMESPACE || print_warning "Namespace not found"
    
    echo ""
    echo "=== Helm Releases ==="
    helm list -n $NAMESPACE || print_warning "No releases found"
    
    echo ""
    echo "=== Pods ==="
    kubectl get pods -n $NAMESPACE -o wide || print_warning "No pods found"
    
    echo ""
    echo "=== Services ==="
    kubectl get svc -n $NAMESPACE || print_warning "No services found"
    
    echo ""
    echo "=== Gateways ==="
    kubectl get gateway -n $NAMESPACE || print_warning "No gateways found"
    
    echo ""
    echo "=== HTTP Routes ==="
    kubectl get httproute -n $NAMESPACE || print_warning "No HTTP routes found"
    
    echo ""
    echo "=== Persistent Volumes ==="
    kubectl get pvc -n $NAMESPACE || print_warning "No PVCs found"
}

# Function to show deployment info
show_deployment_info() {
    print_status "Deployment Information:"
    echo "  Environment: $ENVIRONMENT"
    echo "  Namespace: $NAMESPACE"
    echo "  Release Name: $RELEASE_NAME"
    echo "  Values File: $VALUES_FILE"
    echo "  Action: $ACTION"
    echo ""
}

# Main script logic
main() {
    # Parse arguments
    if [ $# -eq 0 ]; then
        usage
        exit 1
    fi
    
    ENVIRONMENT=$1
    ACTION=${2:-deploy}
    
    # Validate inputs
    validate_environment
    set_environment_vars
    show_deployment_info
    
    # Check prerequisites
    check_prerequisites
    
    # Execute action
    case $ACTION in
        deploy)
            deploy_application
            ;;
        upgrade)
            upgrade_application
            ;;
        delete)
            delete_application
            ;;
        status)
            show_status
            ;;
        *)
            print_error "Invalid action: $ACTION"
            usage
            exit 1
            ;;
    esac
    
    # Show final status if not delete action
    if [ "$ACTION" != "delete" ]; then
        echo ""
        show_status
    fi
}

# Run main function with all arguments
main "$@"
