#!/bin/bash
set -euo pipefail

# Configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly ENCLAVE_NAME="surge-devnet"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Show usage help
show_help() {
    echo "Usage:"
    echo "  $0 [OPTIONS]"
    echo
    echo "Description:"
    echo "  Remove Surge DevNet L1 and clean up all associated resources"
    echo
    echo "Options:"
    echo "  -f, --force     Skip confirmation prompt"
    echo "  -h, --help      Show this help message"
    echo
    echo "Examples:"
    echo "  $0              # Interactive removal with confirmation"
    echo "  $0 --force      # Remove without confirmation"
    exit 0
}

# Parse command line arguments
parse_arguments() {
    local force_removal=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--force)
                force_removal=true
                shift
                ;;
            -h|--help)
                show_help
                ;;
            *)
                log_error "Unknown parameter: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    echo "$force_removal"
}

# Check if enclave exists
check_enclave_exists() {
    if kurtosis enclave ls | grep -q "$ENCLAVE_NAME"; then
        return 0  # Enclave exists
    else
        return 1  # Enclave doesn't exist
    fi
}

# Get enclave status
get_enclave_status() {
    local status=$(kurtosis enclave ls | grep "$ENCLAVE_NAME" | awk '{print $3}' 2>/dev/null || echo "NOT_FOUND")
    echo "$status"
}

# Prompt for confirmation
prompt_confirmation() {
    echo
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "  ⚠️  Confirm Surge DevNet L1 Removal                          "
    echo "║══════════════════════════════════════════════════════════════║"
    echo "║  This will permanently remove:                               ║"
    echo "║  • All running services and containers                       ║"
    echo "║  • Network configuration and data                            ║"
    echo "║  • Generated keys and artifacts                              ║"
    echo "║                                                              ║"
    echo "║  Are you sure you want to continue?                          ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo
    read -p "Enter 'yes' to confirm removal: " confirmation
    
    if [[ "$confirmation" == "yes" ]]; then
        return 0
    else
        return 1
    fi
}

# Simple progress indicator for removal
show_removal_progress() {
    local pid=$1
    local message="$2"
    local spinner='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    printf "%s " "$message"
    while kill -0 $pid 2>/dev/null; do
        printf "\b%s" "${spinner:i++%${#spinner}:1}"
        sleep 0.1
    done
    printf "\b\n"
}

# Remove enclave
remove_enclave() {
    log_info "Removing Surge DevNet L1 enclave..."
    
    # Remove enclave in background to show progress
    kurtosis enclave rm "$ENCLAVE_NAME" --force >/dev/null 2>&1 &
    local remove_pid=$!
    
    echo
    show_removal_progress $remove_pid "Stopping and removing services..."
    echo
    
    # Wait for completion and check status
    wait $remove_pid
    local exit_status=$?
    
    if [[ $exit_status -eq 0 ]]; then
        log_success "Enclave removed successfully"
        return 0
    else
        log_error "Failed to remove enclave"
        return 1
    fi
}

# Clean up system resources
cleanup_system() {
    log_info "Cleaning up system resources..."
    
    # Clean up in background to show progress
    kurtosis clean -a >/dev/null 2>&1 &
    local cleanup_pid=$!
    
    echo
    show_removal_progress $cleanup_pid "Cleaning up unused resources..."
    echo
    
    # Wait for completion and check status
    wait $cleanup_pid
    local exit_status=$?
    
    if [[ $exit_status -eq 0 ]]; then
        log_success "System cleanup completed"
        return 0
    else
        log_warning "System cleanup completed with warnings"
        return 0  # Don't fail the script for cleanup warnings
    fi
}

# Display removal summary
display_removal_summary() {
    echo
    log_info "Removal Summary:"
    echo
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  Surge DevNet L1 has been completely removed.                ║"
    echo "║  All associated services, containers,                        ║"
    echo "║  and data have been cleaned up.                              ║"
    echo "║                                                              ║"
    echo "║  To deploy a new instance, run:                              ║"
    echo "║  ./deploy-surge-devnet-l1.sh                                 ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo
}

# Main function
main() {
    # Show help if requested
    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        show_help
    fi

    # Parse arguments
    local force_removal
    force_removal=$(parse_arguments "$@")
    
    log_info "Starting $SCRIPT_NAME..."

    # Check dependencies
    if ! command -v kurtosis >/dev/null 2>&1; then
        log_error "Required command 'kurtosis' not found. Please install it first."
        exit 1
    fi
    
    # Check if enclave exists
    if ! check_enclave_exists; then
        log_warning "Surge DevNet L1 enclave '$ENCLAVE_NAME' not found"
        log_info "Nothing to remove. System is already clean."
        exit 0
    fi
    
    # Show current status
    local status=$(get_enclave_status)
    log_info "Found Surge DevNet L1 enclave (Status: $status)"
    
    # Get confirmation unless force flag is used
    if [[ "$force_removal" != "true" ]]; then
        if ! prompt_confirmation; then
            log_info "Removal cancelled by user"
            exit 0
        fi
    fi
    
    echo
    log_info "Beginning Surge DevNet L1 removal process..."
    
    # Remove the enclave
    if ! remove_enclave; then
        log_error "Failed to remove Surge DevNet L1"
        exit 1
    fi
    
    # Clean up system resources
    cleanup_system
    
    # Display summary
    display_removal_summary
    
    log_success "Surge DevNet L1 removal complete!"
}

# Run main function
main "$@"
