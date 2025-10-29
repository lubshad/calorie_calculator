#!/bin/bash

# Deploy Script for Calorie Calculator
# This script deploys only the index.html file to the server

set -e

# Configuration
SSH_KEY="lubshad4u4@gmail.com"
SERVER_HOST="admin.zayanfitness.in"
SERVER_USER="root"
SERVER_PORT="22"
REMOTE_PATH="/var/www/calorie_calculator"
LOCAL_BUILD_PATH="./"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help                 Show this help message"
    echo "  -b, --build-only           Only build the Flutter web app (don't deploy)"
    echo "  -d, --deploy-only          Only deploy (skip build, assumes build exists)"
    echo "  -c, --clean                Clean build directory before building"
    echo ""
    echo "Examples:"
    echo "  $0                         # Build and deploy"
    echo "  $0 --build-only            # Only build locally"
    echo "  $0 --deploy-only           # Only deploy existing build"
    echo "  $0 --clean                 # Clean build and deploy"
    echo ""
}

# (No build required)

# # Function to clean build directory
# clean_build() {
#     print_status "Cleaning build directory..."
#     if [ -d "$LOCAL_BUILD_PATH" ]; then
#         rm -rf "$LOCAL_BUILD_PATH"
#         print_success "Build directory cleaned"
#     else
#         print_warning "Build directory doesn't exist, nothing to clean"
#     fi
# }

# (No build step; we only deploy an existing index.html)


# Function to sync build to server
deploy_to_server() {
    print_status "Deploying to server..."
    
    # Ensure index.html exists locally
    if [ ! -f "$LOCAL_BUILD_PATH/index.html" ]; then
        print_error "index.html not found at $LOCAL_BUILD_PATH/index.html"
        exit 1
    fi
    
    # Create remote directory if it doesn't exist
    print_status "Ensuring remote directory exists..."
    ssh -i "$SSH_KEY" -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" \
        "sudo mkdir -p '$REMOTE_PATH'"
    
    # Upload only index.html to server (no deletion of other files)
    print_status "Uploading index.html to server..."
    rsync -avz \
        -e "ssh -i $SSH_KEY -p $SERVER_PORT" \
        "$LOCAL_BUILD_PATH/index.html" \
        "$SERVER_USER@$SERVER_HOST:$REMOTE_PATH/index.html"
    
    # Set proper permissions
    print_status "Setting proper permissions..."
    ssh -i "$SSH_KEY" -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" \
        "sudo chown -R www-data:www-data '$REMOTE_PATH' && sudo chmod -R 755 '$REMOTE_PATH'"
    
    print_success "Deployment completed successfully"
}

# Function to verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    # Check if index.html exists
    ssh -i "$SSH_KEY" -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" \
        "if [ -f '$REMOTE_PATH/index.html' ]; then echo 'index.html found'; else echo 'index.html missing'; exit 1; fi"
    
    print_success "Deployment verified - index.html is present"
}

# Parse arguments
BUILD_ONLY=false
DEPLOY_ONLY=false
# CLEAN_BUILD=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -b|--build-only)
            BUILD_ONLY=true
            shift
            ;;
        -d|--deploy-only)
            DEPLOY_ONLY=true
            shift
            ;;
        # -c|--clean)
        #     CLEAN_BUILD=true
        #     shift
        #     ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution
print_status "Starting Calorie Calculator index.html deployment..."

# Clean build if requested
# if [ "$CLEAN_BUILD" = true ]; then
#     clean_build
# fi

# Skipping build; only deploying existing index.html

# Deploy to server (unless build-only)
if [ "$BUILD_ONLY" = false ]; then
    # Deploy to server
    deploy_to_server
    
    # Verify deployment
    verify_deployment
    
    print_success "Index.html deployment completed successfully!"
    print_status "Your app should be available at: http://$SERVER_HOST"
else
    print_success "Nothing to build. Use --deploy-only to just deploy index.html."
fi