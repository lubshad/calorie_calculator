#!/bin/bash

# SSH Connection Script for Omor Server
# This script provides easy access to the omor server

set -e

# Configuration
SSH_KEY="lubshad4u4@gmail.com"
SERVER_HOST="admin.zayanfitness.in"
SERVER_USER="omor"
SERVER_PORT="22"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
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

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [COMMAND]"
    echo ""
    echo "Options:"
    echo "  -h, --help                 Show this help message"
    echo "  -c, --command COMMAND     Execute a command on the server"
    echo "  -i, --interactive          Connect interactively (default)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Interactive SSH session"
    echo "  $0 --command 'ls -la'                # Execute command and return"
    echo "  $0 --command 'sudo systemctl status nginx'  # Check nginx status"
    echo ""
}

# Function to execute command remotely
execute_command() {
    local cmd="$1"
    print_status "Executing command on $SERVER_USER@$SERVER_HOST: $cmd"
    ssh -i "$SSH_KEY" -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" "$cmd"
}

# Function to connect interactively
connect_interactive() {
    print_status "Connecting to $SERVER_USER@$SERVER_HOST..."
    print_success "Connected! Use 'exit' to disconnect."
    ssh -i "$SSH_KEY" -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST"
}

# Parse arguments
INTERACTIVE=true
COMMAND=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -c|--command)
            COMMAND="$2"
            INTERACTIVE=false
            shift 2
            ;;
        -i|--interactive)
            INTERACTIVE=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Execute based on mode
if [ "$INTERACTIVE" = true ]; then
    connect_interactive
else
    execute_command "$COMMAND"
fi