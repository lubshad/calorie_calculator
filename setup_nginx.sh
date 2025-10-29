#!/bin/bash

# Nginx Setup Script for Calorie Calculator
# This script sets up nginx configuration on the server

set -e

# Configuration
SSH_KEY="lubshad4u4@gmail.com"
SERVER_HOST="admin.zayanfitness.in"
SERVER_USER="root"
SERVER_PORT="22"
NGINX_CONFIG_FILE="/etc/nginx/sites-available/calorie_calculator"
NGINX_CONFIG_ENABLED="/etc/nginx/sites-enabled/calorie_calculator"
WEB_ROOT="/var/www/calorie_calculator"

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
    echo "  -c, --check                Check nginx configuration status"
    echo "  -r, --reload               Reload nginx configuration"
    echo "  -t, --test                 Test nginx configuration"
    echo "  --remove                   Remove nginx configuration"
    echo ""
    echo "Examples:"
    echo "  $0                         # Setup nginx configuration"
    echo "  $0 --check                 # Check current status"
    echo "  $0 --reload                # Reload nginx after changes"
    echo "  $0 --remove                # Remove configuration"
    echo ""
}

# Function to check nginx status
check_nginx_status() {
    print_status "Checking nginx status..."
    
    # Check if nginx is installed
    ssh -i "$SSH_KEY" -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" \
        "if command -v nginx &> /dev/null; then echo 'Nginx is installed'; else echo 'Nginx is not installed'; exit 1; fi"
    
    # Check if nginx is running
    ssh -i "$SSH_KEY" -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" \
        "if systemctl is-active --quiet nginx; then echo 'Nginx is running'; else echo 'Nginx is not running'; fi"
    
    # Check if our config exists
    ssh -i "$SSH_KEY" -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" \
        "if [ -f '$NGINX_CONFIG_FILE' ]; then echo 'Configuration file exists'; else echo 'Configuration file does not exist'; fi"
    
    # Check if config is enabled
    ssh -i "$SSH_KEY" -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" \
        "if [ -L '$NGINX_CONFIG_ENABLED' ]; then echo 'Configuration is enabled'; else echo 'Configuration is not enabled'; fi"
    
    # Check web root
    ssh -i "$SSH_KEY" -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" \
        "if [ -d '$WEB_ROOT' ]; then echo 'Web root exists'; else echo 'Web root does not exist'; fi"
}


# Function to install nginx if not present
install_nginx() {
    print_status "Checking and installing nginx..."
    
    ssh -i "$SSH_KEY" -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" \
        "if ! command -v nginx &> /dev/null; then \
            echo 'Installing nginx...'; \
            sudo apt update && sudo apt install -y nginx; \
            sudo systemctl enable nginx; \
            sudo systemctl start nginx; \
            echo 'Nginx installed and started'; \
        else \
            echo 'Nginx is already installed'; \
        fi"
    
    print_success "Nginx installation check completed"
}

# Function to create web directory
create_web_directory() {
    print_status "Creating web directory..."
    
    ssh -i "$SSH_KEY" -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" \
        "sudo mkdir -p '$WEB_ROOT' && \
         sudo chown -R www-data:www-data '$WEB_ROOT' && \
         sudo chmod -R 755 '$WEB_ROOT'"
    
    print_success "Web directory created with proper permissions"
}

# Function to upload nginx configuration
upload_nginx_config() {
    print_status "Uploading nginx configuration..."
    
    # Check if nginx_configuration file exists
    if [ ! -f "nginx_configuration" ]; then
        print_error "nginx_configuration file not found in current directory"
        exit 1
    fi
    
    # Upload config file directly to server
    scp -i "$SSH_KEY" -P "$SERVER_PORT" "nginx_configuration" "$SERVER_USER@$SERVER_HOST:/tmp/calorie_calculator_nginx.conf"
    
    # Move to proper location and set permissions
    ssh -i "$SSH_KEY" -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" \
        "sudo mv /tmp/calorie_calculator_nginx.conf '$NGINX_CONFIG_FILE' && \
         sudo chown root:root '$NGINX_CONFIG_FILE' && \
         sudo chmod 644 '$NGINX_CONFIG_FILE'"
    
    print_success "Nginx configuration uploaded from nginx_configuration file"
}

# Function to enable nginx configuration
enable_nginx_config() {
    print_status "Enabling nginx configuration..."
    
    ssh -i "$SSH_KEY" -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" \
        "sudo ln -sf '$NGINX_CONFIG_FILE' '$NGINX_CONFIG_ENABLED'"
    
    print_success "Nginx configuration enabled"
}

# Function to test nginx configuration
test_nginx_config() {
    print_status "Testing nginx configuration..."
    
    ssh -i "$SSH_KEY" -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" \
        "sudo nginx -t"
    
    if [ $? -eq 0 ]; then
        print_success "Nginx configuration test passed"
    else
        print_error "Nginx configuration test failed"
        exit 1
    fi
}

# Function to reload nginx
reload_nginx() {
    print_status "Reloading nginx..."
    
    ssh -i "$SSH_KEY" -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" \
        "sudo systemctl reload nginx"
    
    print_success "Nginx reloaded successfully"
}

# Function to remove nginx configuration
remove_nginx_config() {
    print_status "Removing nginx configuration..."
    
    # Disable configuration
    ssh -i "$SSH_KEY" -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" \
        "if [ -L '$NGINX_CONFIG_ENABLED' ]; then sudo rm '$NGINX_CONFIG_ENABLED'; echo 'Configuration disabled'; fi"
    
    # Remove configuration file
    ssh -i "$SSH_KEY" -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" \
        "if [ -f '$NGINX_CONFIG_FILE' ]; then sudo rm '$NGINX_CONFIG_FILE'; echo 'Configuration file removed'; fi"
    
    # Reload nginx
    ssh -i "$SSH_KEY" -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" \
        "sudo systemctl reload nginx"
    
    print_success "Nginx configuration removed"
}

# Parse arguments
CHECK_ONLY=false
RELOAD_ONLY=false
TEST_ONLY=false
REMOVE_CONFIG=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -c|--check)
            CHECK_ONLY=true
            shift
            ;;
        -r|--reload)
            RELOAD_ONLY=true
            shift
            ;;
        -t|--test)
            TEST_ONLY=true
            shift
            ;;
        --remove)
            REMOVE_CONFIG=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution
if [ "$CHECK_ONLY" = true ]; then
    check_nginx_status
elif [ "$RELOAD_ONLY" = true ]; then
    reload_nginx
elif [ "$TEST_ONLY" = true ]; then
    test_nginx_config
elif [ "$REMOVE_CONFIG" = true ]; then
    remove_nginx_config
else
    print_status "Starting nginx setup for Omor Admin Panel..."
    
    # Check current status
    check_nginx_status
    
    # Install nginx if needed
    install_nginx
    
    # Create web directory
    create_web_directory
    
    # Upload nginx configuration
    upload_nginx_config
    
    # Enable configuration
    enable_nginx_config
    
    # Test configuration
    test_nginx_config
    
    # Reload nginx
    reload_nginx
    
    print_success "Nginx setup completed successfully!"
    print_status "Your app should be accessible at: http://zayanfitness.in"
fi