#!/bin/bash
# This script attempts to list users who can switch to root or have administrative privileges.

echo "=== 1. Users with UID 0 (root-equivalent accounts) ==="
# List accounts from /etc/passwd that have a UID of 0.
awk -F: '($3 == 0) {print " - " $1}' /etc/passwd
echo

echo "=== 2. Users in Administrative Groups ==="
# Define groups that are typically used for administrative privileges.
admin_groups=("sudo" "wheel" "admin")

for group in "${admin_groups[@]}"; do
    # Check if the group exists on the system.
    if getent group "$group" > /dev/null; then
        # Retrieve the comma-separated list of members.
        members=$(getent group "$group" | awk -F: '{print $4}')
        echo "Group: $group"
        if [ -n "$members" ]; then
            # Split the member list by commas and display each user.
            IFS=',' read -ra userlist <<< "$members"
            for user in "${userlist[@]}"; do
                echo " - $user"
            done
        else
            echo " - (no members listed)"
        fi
    else
        echo "Group '$group' does not exist on this system."
    fi
    echo
done

echo "=== 3. Sudoers File Entries (Additional Administrative Privileges) ==="
# Display lines from /etc/sudoers and /etc/sudoers.d/ that are not commented out and that reference ALL.
# (This is a very simple filter. The sudoers file syntax can be complex.)
sudo grep -R "^[^#].*ALL" /etc/sudoers /etc/sudoers.d/ 2>/dev/null | grep -v "Defaults" || echo "No sudoers entries found or insufficient permissions."
