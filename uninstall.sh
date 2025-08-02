#!/bin/bash

# GeekWorm X735 Power Management Board Uninstallation Script
# This script completely removes all X735 components installed by x735_install.sh
# Usage: sudo ./uninstall.sh
# Author: Mikey Nichols

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to check if running as root/sudo
check_privileges() {
    print_status "Checking user privileges..."
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root or with sudo privileges"
        echo "Please run: sudo $0"
        exit 1
    fi
    print_success "Running with appropriate privileges"
}

# Function to stop and disable X735 services
remove_x735_services() {
    print_status "Stopping and removing X735 services..."
    
    # Array of X735 services to remove
    local services=("x735-fan" "x735-pwr")
    
    for service in "${services[@]}"; do
        print_status "Processing service: $service"
        
        # Stop the service if it's running
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            print_status "Stopping $service service..."
            if systemctl stop "$service"; then
                print_success "$service service stopped"
            else
                print_warning "Failed to stop $service service (may not be running)"
            fi
        else
            print_status "$service service is not running"
        fi
        
        # Disable the service if it's enabled
        if systemctl is-enabled --quiet "$service" 2>/dev/null; then
            print_status "Disabling $service service..."
            if systemctl disable "$service"; then
                print_success "$service service disabled"
            else
                print_warning "Failed to disable $service service"
            fi
        else
            print_status "$service service is not enabled"
        fi
        
        # Remove the service file
        local service_file="/lib/systemd/system/${service}.service"
        if [[ -f "$service_file" ]]; then
            print_status "Removing service file: $service_file"
            if rm -f "$service_file"; then
                print_success "Service file removed: $service_file"
            else
                print_error "Failed to remove service file: $service_file"
            fi
        else
            print_status "Service file not found: $service_file"
        fi
    done
    
    # Reload systemd daemon to reflect changes
    print_status "Reloading systemd daemon..."
    if systemctl daemon-reload; then
        print_success "Systemd daemon reloaded"
    else
        print_warning "Failed to reload systemd daemon"
    fi
}

# Function to remove X735 service scripts
remove_service_scripts() {
    print_status "Removing X735 service scripts..."
    
    local scripts=(
        "/usr/local/bin/x735-fan.sh"
        "/usr/local/bin/xPWR.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            print_status "Removing script: $script"
            if rm -f "$script"; then
                print_success "Script removed: $script"
            else
                print_error "Failed to remove script: $script"
            fi
        else
            print_status "Script not found: $script"
        fi
    done
}

# Function to remove xSoft utility and symlinks
remove_xsoft_utility() {
    print_status "Removing xSoft utility..."
    
    # Remove xSoft symlink
    if [[ -L "/usr/local/bin/xSoft" ]]; then
        print_status "Removing xSoft symlink..."
        if rm -f "/usr/local/bin/xSoft"; then
            print_success "xSoft symlink removed"
        else
            print_error "Failed to remove xSoft symlink"
        fi
    else
        print_status "xSoft symlink not found"
    fi
    
    # Remove xSoft.sh script
    if [[ -f "/usr/local/bin/xSoft.sh" ]]; then
        print_status "Removing xSoft.sh script..."
        if rm -f "/usr/local/bin/xSoft.sh"; then
            print_success "xSoft.sh script removed"
        else
            print_error "Failed to remove xSoft.sh script"
        fi
    else
        print_status "xSoft.sh script not found"
    fi
}

# Function to remove x735off power-down script
remove_power_off_script() {
    print_status "Removing x735off power-down script..."
    
    if [[ -f "/usr/local/bin/x735off" ]]; then
        print_status "Removing x735off script..."
        if rm -f "/usr/local/bin/x735off"; then
            print_success "x735off script removed"
        else
            print_error "Failed to remove x735off script"
        fi
    else
        print_status "x735off script not found"
    fi
}

# Function to remove X735 utility scripts directory
remove_x735_directory() {
    print_status "Removing X735 utility scripts directory..."
    
    if [[ -d "/usr/local/bin/x735" ]]; then
        print_status "Removing /usr/local/bin/x735 directory and contents..."
        if rm -rf "/usr/local/bin/x735"; then
            print_success "/usr/local/bin/x735 directory removed"
        else
            print_error "Failed to remove /usr/local/bin/x735 directory"
        fi
    else
        print_status "/usr/local/bin/x735 directory not found"
    fi
}

# Function to remove legacy files (from older versions)
remove_legacy_files() {
    print_status "Removing legacy X735 files..."
    
    local legacy_files=(
        "/usr/local/bin/pwm_fan_control.py"
        "/usr/local/bin/read_fan_speed.py"
    )
    
    for file in "${legacy_files[@]}"; do
        if [[ -f "$file" ]]; then
            print_status "Removing legacy file: $file"
            if rm -f "$file"; then
                print_success "Legacy file removed: $file"
            else
                print_error "Failed to remove legacy file: $file"
            fi
        else
            print_status "Legacy file not found: $file"
        fi
    done
}

# Function to remove bashrc aliases
remove_bashrc_aliases() {
    print_status "Removing X735 aliases from bashrc files..."
    
    # Remove from root's bashrc
    if [[ -f "/root/.bashrc" ]]; then
        print_status "Removing X735 aliases from /root/.bashrc..."
        sed -i '/x735off/d' /root/.bashrc 2>/dev/null || true
        print_success "X735 aliases removed from /root/.bashrc"
    fi
    
    # Remove from current user's bashrc if different from root
    if [[ -n "$SUDO_USER" ]] && [[ "$SUDO_USER" != "root" ]]; then
        local user_bashrc="/home/$SUDO_USER/.bashrc"
        if [[ -f "$user_bashrc" ]]; then
            print_status "Removing X735 aliases from $user_bashrc..."
            sed -i '/x735off/d' "$user_bashrc" 2>/dev/null || true
            print_success "X735 aliases removed from $user_bashrc"
        fi
    fi
}

# Function to remove start menu entries
remove_start_menu_entries() {
    print_status "Removing X735 start menu entries..."
    
    # Get the default user (not root, in case running with sudo)
    local default_user="${SUDO_USER:-$(logname 2>/dev/null || whoami)}"
    local user_home
    
    # Try to get the user's home directory
    if [[ -n "$SUDO_USER" ]]; then
        user_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    else
        user_home="$HOME"
    fi
    
    # Fallback if we can't determine user home
    if [[ -z "$user_home" ]] || [[ "$user_home" == "/root" ]]; then
        print_warning "Could not determine user home directory, trying /home/pi"
        user_home="/home/pi"
        default_user="pi"
    fi
    
    print_status "Removing start menu entries for user: $default_user (home: $user_home)"
    
    local apps_dir="$user_home/.local/share/applications"
    
    # Array of X735 desktop entries to remove
    local desktop_entries=(
        "x735-xSoft.desktop"
        "x735-x735off.desktop"
        "x735-pwm_fan_control.py.desktop"
        "x735-read_fan_speed.py.desktop"
        "x735-folder.directory"
    )
    
    for entry in "${desktop_entries[@]}"; do
        local entry_path="$apps_dir/$entry"
        if [[ -f "$entry_path" ]]; then
            print_status "Removing start menu entry: $entry_path"
            if rm -f "$entry_path"; then
                print_success "Start menu entry removed: $entry_path"
            else
                print_error "Failed to remove start menu entry: $entry_path"
            fi
        else
            print_status "Start menu entry not found: $entry_path"
        fi
    done
    
    print_success "Start menu entries removal completed"
}

# Function to remove PWM overlay from config.txt
remove_pwm_overlay() {
    print_status "Removing PWM overlay from config.txt..."
    
    # Check both possible locations for config.txt
    local config_paths=("/boot/config.txt" "/boot/firmware/config.txt")
    local overlay_removed=false
    
    for config_path in "${config_paths[@]}"; do
        if [[ -f "$config_path" ]]; then
            print_status "Checking $config_path for PWM overlay..."
            
            # Check if overlay exists in this config file
            if grep -q "dtoverlay=pwm-2chan,pin2=13,func2=4" "$config_path" 2>/dev/null; then
                print_status "Found PWM overlay in $config_path, creating backup..."
                
                # Create backup before removing
                local backup_file="${config_path}.backup.uninstall.$(date +%Y%m%d_%H%M%S)"
                if cp "$config_path" "$backup_file"; then
                    print_success "Backup created: $backup_file"
                else
                    print_warning "Failed to create backup, proceeding anyway..."
                fi
                
                # Remove the PWM overlay line
                print_status "Removing PWM overlay from $config_path..."
                if sed -i '/dtoverlay=pwm-2chan,pin2=13,func2=4/d' "$config_path"; then
                    print_success "PWM overlay removed from $config_path"
                    overlay_removed=true
                else
                    print_error "Failed to remove PWM overlay from $config_path"
                fi
            else
                print_status "PWM overlay not found in $config_path"
            fi
        else
            print_status "Config file not found: $config_path"
        fi
    done
    
    if ! $overlay_removed; then
        print_warning "PWM overlay was not found in any config.txt file"
    fi
}

# Function to clean up temporary directories
cleanup_temp_directories() {
    print_status "Cleaning up temporary directories..."
    
    local temp_dirs=(
        "/var/tmp/raspberry-config"
        "/tmp/x735-script"
    )
    
    for temp_dir in "${temp_dirs[@]}"; do
        if [[ -d "$temp_dir" ]]; then
            print_status "Removing temporary directory: $temp_dir"
            if rm -rf "$temp_dir"; then
                print_success "Temporary directory removed: $temp_dir"
            else
                print_error "Failed to remove temporary directory: $temp_dir"
            fi
        else
            print_status "Temporary directory not found: $temp_dir"
        fi
    done
}

# Function to verify uninstallation
verify_uninstallation() {
    print_status "Verifying X735 uninstallation..."
    
    local checks_passed=0
    local total_checks=7
    
    # Check if services are gone
    if ! systemctl list-unit-files | grep -q x735 2>/dev/null; then
        print_success "✓ X735 services removed"
        ((checks_passed++))
    else
        print_error "✗ X735 services still present"
    fi
    
    # Check if xSoft utility is gone
    if [[ ! -f "/usr/local/bin/xSoft.sh" ]] && [[ ! -L "/usr/local/bin/xSoft" ]]; then
        print_success "✓ xSoft utility removed"
        ((checks_passed++))
    else
        print_error "✗ xSoft utility still present"
    fi
    
    # Check if x735off script is gone
    if [[ ! -f "/usr/local/bin/x735off" ]]; then
        print_success "✓ x735off script removed"
        ((checks_passed++))
    else
        print_error "✗ x735off script still present"
    fi
    
    # Check if x735 directory is gone
    if [[ ! -d "/usr/local/bin/x735" ]]; then
        print_success "✓ X735 utility directory removed"
        ((checks_passed++))
    else
        print_error "✗ X735 utility directory still present"
    fi
    
    # Check if PWM overlay is removed from config files
    local overlay_found=false
    for config_path in "/boot/config.txt" "/boot/firmware/config.txt"; do
        if [[ -f "$config_path" ]] && grep -q "dtoverlay=pwm-2chan,pin2=13,func2=4" "$config_path" 2>/dev/null; then
            overlay_found=true
            break
        fi
    done
    
    if ! $overlay_found; then
        print_success "✓ PWM overlay removed from config.txt"
        ((checks_passed++))
    else
        print_error "✗ PWM overlay still present in config.txt"
    fi
    
    # Check if legacy files are gone
    if [[ ! -f "/usr/local/bin/pwm_fan_control.py" ]] && [[ ! -f "/usr/local/bin/read_fan_speed.py" ]]; then
        print_success "✓ Legacy files removed"
        ((checks_passed++))
    else
        print_error "✗ Legacy files still present"
    fi
    
    # Check if start menu entries are gone
    local default_user="${SUDO_USER:-$(logname 2>/dev/null || whoami)}"
    local user_home
    if [[ -n "$SUDO_USER" ]]; then
        user_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    else
        user_home="$HOME"
    fi
    if [[ -z "$user_home" ]] || [[ "$user_home" == "/root" ]]; then
        user_home="/home/pi"
    fi
    
    if [[ ! -f "$user_home/.local/share/applications/x735-xSoft.desktop" ]]; then
        print_success "✓ Start menu entries removed"
        ((checks_passed++))
    else
        print_error "✗ Start menu entries still present"
    fi
    
    echo
    print_status "Uninstallation verification: $checks_passed/$total_checks checks passed"
    
    if [[ $checks_passed -eq $total_checks ]]; then
        print_success "All checks passed! X735 components successfully removed."
        return 0
    else
        print_warning "Some checks failed. Some X735 components may still be present."
        return 1
    fi
}

# Function to display post-uninstallation information
show_post_uninstall_info() {
    echo
    print_success "=== X735 Power Management Board Uninstallation Complete ==="
    echo
    echo "The following X735 components have been removed:"
    echo "  • X735 fan and power management services"
    echo "  • xSoft utility and symlinks"
    echo "  • x735off power-down script"
    echo "  • X735 utility scripts directory (/usr/local/bin/x735/)"
    echo "  • PWM overlay from config.txt"
    echo "  • Bashrc aliases"
    echo "  • Start menu entries"
    echo "  • Temporary installation directories"
    echo
    echo "Next steps:"
    echo "  • Reboot your Raspberry Pi to fully disable the PWM overlay"
    echo "  • The X735 board will no longer be managed by software"
    echo
    print_warning "Remember to reboot to complete the uninstallation process!"
    echo
}

# Main uninstallation function
uninstall_x735() {
    echo
    print_status "=== Starting GeekWorm X735 Power Management Board Uninstallation ==="
    echo
    
    # Run all uninstallation steps
    check_privileges
    remove_x735_services
    remove_service_scripts
    remove_xsoft_utility
    remove_power_off_script
    remove_x735_directory
    remove_legacy_files
    remove_bashrc_aliases
    remove_start_menu_entries
    remove_pwm_overlay
    cleanup_temp_directories
    verify_uninstallation
    show_post_uninstall_info
    
    return 0
}

# If script is being run directly (not sourced), execute the uninstallation
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    uninstall_x735
    exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        print_success "Uninstallation completed successfully!"
        echo
        print_status "Reboot recommended to complete the removal of PWM overlay."
    else
        print_error "Uninstallation failed with exit code $exit_code"
        exit $exit_code
    fi
fi
