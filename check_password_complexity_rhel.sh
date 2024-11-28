#!/bin/bash

# Function to check pam_pwquality settings in /etc/pam.d/system-auth
check_pam_pwquality() {
    local pam_file="/etc/pam.d/system-auth"
    echo "Checking PAM configuration in $pam_file for password complexity requirements..."

    if [ -f "$pam_file" ]; then
        if grep -q "pam_pwquality.so" "$pam_file"; then
            echo "Found 'pam_pwquality.so' in $pam_file."
            echo "Current settings:"
            grep "pam_pwquality.so" "$pam_file"
        else
            echo "'pam_pwquality.so' is not configured in $pam_file."
        fi
    else
        echo "PAM file $pam_file does not exist. Ensure your system uses this file for password policies."
    fi
}

# Function to check /etc/security/pwquality.conf settings
check_pwquality_conf() {
    local conf_file="/etc/security/pwquality.conf"
    echo "Checking $conf_file for password policies..."

    if [ -f "$conf_file" ]; then
        echo "Found $conf_file. Current settings:"
        cat "$conf_file"
    else
        echo "$conf_file not found. Consider creating it to define password complexity requirements."
    fi
}

# Main script execution
echo "CentOS/RHEL Password Complexity Check Script"
echo "-------------------------------------------"

# Check PAM configuration
check_pam_pwquality
echo

# Check pwquality.conf settings
check_pwquality_conf
echo

echo "Password complexity check for CentOS/RHEL completed."

