#!/bin/bash

# SSH Key Management Script
# Manages SSH known_hosts entries and SSH connections

set -e

# Default values
SSH_DIR="$HOME/.ssh"
KNOWN_HOSTS="$SSH_DIR/known_hosts"
DEFAULT_HOST="rk3399.local"
DEFAULT_PORT="2222"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to show usage
show_usage() {
    cat << EOF
SSH Key Management Script

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    remove-host [HOST] [PORT]    Remove host from known_hosts (default: rk3399.local:2222)
    add-host [HOST] [PORT]       Add host to known_hosts
    list-hosts                   List all hosts in known_hosts
    clean-known-hosts           Clean up known_hosts file
    backup-known-hosts          Backup known_hosts file
    restore-known-hosts         Restore known_hosts from backup
    test-connection [HOST] [PORT] Test SSH connection to host
    generate-key [TYPE]         Generate new SSH key pair (rsa, ed25519, ecdsa)
    help                        Show this help message

Options:
    -h, --help                  Show this help message
    -v, --verbose               Verbose output

Examples:
    $0 remove-host                          # Remove rk3399.local:2222 from known_hosts
    $0 remove-host pi.local 22              # Remove pi.local:22 from known_hosts
    $0 add-host rk3399.local 2222           # Add rk3399.local:2222 to known_hosts
    $0 test-connection rk3399.local 2222    # Test connection to rk3399.local:2222
    $0 generate-key ed25519                 # Generate new ed25519 SSH key

EOF
}

# Function to ensure SSH directory exists
ensure_ssh_dir() {
    if [[ ! -d "$SSH_DIR" ]]; then
        print_info "Creating SSH directory: $SSH_DIR"
        mkdir -p "$SSH_DIR"
        chmod 700 "$SSH_DIR"
    fi
    
    if [[ ! -f "$KNOWN_HOSTS" ]]; then
        print_info "Creating known_hosts file: $KNOWN_HOSTS"
        touch "$KNOWN_HOSTS"
        chmod 644 "$KNOWN_HOSTS"
    fi
}

# Function to remove host from known_hosts
remove_host() {
    local host="${1:-$DEFAULT_HOST}"
    local port="${2:-$DEFAULT_PORT}"
    local host_entry="[$host]:$port"
    
    ensure_ssh_dir
    
    print_info "Removing $host_entry from known_hosts..."
    
    if ssh-keygen -f "$KNOWN_HOSTS" -R "$host_entry" 2>/dev/null; then
        print_success "Successfully removed $host_entry from known_hosts"
    else
        print_warning "$host_entry not found in known_hosts or already removed"
    fi
    
    # Also try to remove without brackets (standard port 22)
    if [[ "$port" == "22" ]]; then
        if ssh-keygen -f "$KNOWN_HOSTS" -R "$host" 2>/dev/null; then
            print_success "Also removed $host (standard format) from known_hosts"
        fi
    fi
}

# Function to add host to known_hosts
add_host() {
    local host="${1:-$DEFAULT_HOST}"
    local port="${2:-$DEFAULT_PORT}"
    
    ensure_ssh_dir
    
    print_info "Adding $host:$port to known_hosts..."
    
    if ssh-keyscan -p "$port" "$host" >> "$KNOWN_HOSTS" 2>/dev/null; then
        print_success "Successfully added $host:$port to known_hosts"
    else
        print_error "Failed to add $host:$port to known_hosts. Host might be unreachable."
        return 1
    fi
}

# Function to list hosts in known_hosts
list_hosts() {
    ensure_ssh_dir
    
    if [[ ! -f "$KNOWN_HOSTS" ]] || [[ ! -s "$KNOWN_HOSTS" ]]; then
        print_warning "No hosts found in known_hosts file"
        return 0
    fi
    
    print_info "Hosts in known_hosts:"
    echo "----------------------------------------"
    
    # Extract and display host information
    while IFS= read -r line; do
        if [[ -n "$line" && ! "$line" =~ ^# ]]; then
            # Extract hostname/IP from the line
            host_info=$(echo "$line" | awk '{print $1}')
            key_type=$(echo "$line" | awk '{print $2}')
            echo "Host: $host_info (Key type: $key_type)"
        fi
    done < "$KNOWN_HOSTS"
}

# Function to clean known_hosts
clean_known_hosts() {
    ensure_ssh_dir
    
    if [[ ! -f "$KNOWN_HOSTS" ]]; then
        print_warning "No known_hosts file to clean"
        return 0
    fi
    
    print_warning "This will remove all entries from known_hosts file"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        > "$KNOWN_HOSTS"
        print_success "known_hosts file cleaned"
    else
        print_info "Operation cancelled"
    fi
}

# Function to backup known_hosts
backup_known_hosts() {
    ensure_ssh_dir
    
    if [[ ! -f "$KNOWN_HOSTS" ]]; then
        print_warning "No known_hosts file to backup"
        return 0
    fi
    
    local backup_file="${KNOWN_HOSTS}.backup.$(date +%Y%m%d_%H%M%S)"
    
    cp "$KNOWN_HOSTS" "$backup_file"
    print_success "Backup created: $backup_file"
}

# Function to restore known_hosts
restore_known_hosts() {
    ensure_ssh_dir
    
    local backup_files=($(ls -t "${KNOWN_HOSTS}.backup."* 2>/dev/null || true))
    
    if [[ ${#backup_files[@]} -eq 0 ]]; then
        print_error "No backup files found"
        return 1
    fi
    
    print_info "Available backup files:"
    for i in "${!backup_files[@]}"; do
        echo "$((i+1)). ${backup_files[i]}"
    done
    
    read -p "Select backup to restore (1-${#backup_files[@]}): " -r selection
    
    if [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -ge 1 ]] && [[ "$selection" -le ${#backup_files[@]} ]]; then
        local selected_backup="${backup_files[$((selection-1))]}"
        cp "$selected_backup" "$KNOWN_HOSTS"
        print_success "Restored known_hosts from: $selected_backup"
    else
        print_error "Invalid selection"
        return 1
    fi
}

# Function to test SSH connection
test_connection() {
    local host="${1:-$DEFAULT_HOST}"
    local port="${2:-$DEFAULT_PORT}"
    
    print_info "Testing SSH connection to $host:$port..."
    
    if ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no -p "$port" "$host" exit 2>/dev/null; then
        print_success "SSH connection to $host:$port successful"
    else
        print_error "SSH connection to $host:$port failed"
        print_info "You might need to:"
        print_info "1. Check if the host is reachable"
        print_info "2. Verify the port number"
        print_info "3. Ensure SSH service is running on the target"
        return 1
    fi
}

# Function to generate SSH key
generate_key() {
    local key_type="${1:-ed25519}"
    local key_file="$SSH_DIR/id_$key_type"
    
    ensure_ssh_dir
    
    if [[ -f "$key_file" ]]; then
        print_warning "Key file $key_file already exists"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Operation cancelled"
            return 0
        fi
    fi
    
    print_info "Generating $key_type SSH key pair..."
    
    case "$key_type" in
        "rsa")
            ssh-keygen -t rsa -b 4096 -f "$key_file" -N ""
            ;;
        "ed25519")
            ssh-keygen -t ed25519 -f "$key_file" -N ""
            ;;
        "ecdsa")
            ssh-keygen -t ecdsa -b 521 -f "$key_file" -N ""
            ;;
        *)
            print_error "Unsupported key type: $key_type"
            print_info "Supported types: rsa, ed25519, ecdsa"
            return 1
            ;;
    esac
    
    if [[ $? -eq 0 ]]; then
        print_success "SSH key pair generated successfully"
        print_info "Private key: $key_file"
        print_info "Public key: $key_file.pub"
        print_info "Public key content:"
        echo "----------------------------------------"
        cat "$key_file.pub"
        echo "----------------------------------------"
    else
        print_error "Failed to generate SSH key pair"
        return 1
    fi
}

# Main script logic
main() {
    local command="${1:-help}"
    
    case "$command" in
        "remove-host")
            remove_host "$2" "$3"
            ;;
        "add-host")
            add_host "$2" "$3"
            ;;
        "list-hosts")
            list_hosts
            ;;
        "clean-known-hosts")
            clean_known_hosts
            ;;
        "backup-known-hosts")
            backup_known_hosts
            ;;
        "restore-known-hosts")
            restore_known_hosts
            ;;
        "test-connection")
            test_connection "$2" "$3"
            ;;
        "generate-key")
            generate_key "$2"
            ;;
        "help"|"-h"|"--help")
            show_usage
            ;;
        *)
            print_error "Unknown command: $command"
            echo
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
