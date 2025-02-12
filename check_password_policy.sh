#!/usr/bin/env bash
#
# check_password_policy.sh
#
# A script to gather and display password policy information on a Linux system.

# Ensure we are running with at least sudo privileges
if [[ $EUID -ne 0 ]]; then
  echo "Please run this script as root or with sudo."
  exit 1
fi

echo "==============================================="
echo " Password Policy Examination Script"
echo "==============================================="

echo ""
echo "1) Checking /etc/login.defs for PASS_ variables..."
echo "---------------------------------------------------"
if [[ -f /etc/login.defs ]]; then
  grep "^PASS_" /etc/login.defs || echo "No PASS_ entries found in /etc/login.defs"
else
  echo "/etc/login.defs not found."
fi

echo ""
echo "2) Checking PAM configuration for password rules..."
echo "---------------------------------------------------"

# We’ll check both the Debian/Ubuntu (common-password) style and Red Hat style
# (system-auth, password-auth) to see which exist.

PAM_FILES=(
  "/etc/pam.d/common-password"    # Debian/Ubuntu
  "/etc/pam.d/system-auth"        # RHEL/CentOS/Fedora, older versions
  "/etc/pam.d/password-auth"      # RHEL/CentOS/Fedora, sometimes used
)

FOUND_PAM_FILE=false

for pam_file in "${PAM_FILES[@]}"; do
  if [[ -f "$pam_file" ]]; then
    FOUND_PAM_FILE=true
    echo "Found PAM file: $pam_file"
    echo "---------------------------------------------------"
    # Show lines referencing pwquality or cracklib or pam_unix
    grep -E 'pam_pwquality\.so|pam_cracklib\.so|pam_unix\.so' "$pam_file"
    echo ""
  fi
done

if [[ "$FOUND_PAM_FILE" = false ]]; then
  echo "No recognized PAM configuration file found among:"
  for pf in "${PAM_FILES[@]}"; do
    echo " - $pf"
  done
fi

echo ""
echo "3) Checking /etc/security/pwquality.conf..."
echo "---------------------------------------------------"
if [[ -f /etc/security/pwquality.conf ]]; then
  cat /etc/security/pwquality.conf
else
  echo "/etc/security/pwquality.conf not found."
fi

echo ""
echo "4) Checking default values for new users (/etc/default/useradd)..."
echo "---------------------------------------------------"
if [[ -f /etc/default/useradd ]]; then
  cat /etc/default/useradd
else
  echo "/etc/default/useradd not found."
fi

echo ""
echo "5) Summary of per-user password aging (optional)"
echo "---------------------------------------------------"
echo "To check password aging for a specific user, you can run:"
echo "    chage -l <username>"
echo ""
echo "This script does not do it automatically, but here's an example for 'root':"
chage -l root || echo "Unable to run chage -l root."

echo ""
echo "==============================================="
echo " Done. Review the above output for details."
echo "==============================================="
