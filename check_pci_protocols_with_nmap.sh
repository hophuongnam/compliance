#!/usr/bin/env bash
#
# check_pci_protocols_with_nmap.sh
#
# Usage: ./check_pci_protocols_with_nmap.sh <HOST> <PORT>
#
# This script uses Nmap's ssl-enum-ciphers script to detect
# which SSL/TLS protocols are supported by the target. Then
# it provides a simplified PCI DSS 4.0 pass/fail result:
#   - FAIL if SSLv3, TLS 1.0, or TLS 1.1 is detected.
#   - FAIL if neither TLS 1.2 nor TLS 1.3 is supported.
#   - Otherwise PASS.

HOST="$1"
PORT="$2"

if [[ -z "$HOST" || -z "$PORT" ]]; then
  echo "Usage: $0 <HOST> <PORT>"
  echo "Example: $0 example.com 443"
  exit 1
fi

echo "Running Nmap ssl-enum-ciphers against $HOST on port $PORT ..."
echo

# Run Nmap with the ssl-enum-ciphers script
# -p <PORT>        : specify the port
# --script <SCRIPT>: run the ssl-enum-ciphers NSE script
# --script-args    : can provide additional script arguments if needed
OUTPUT=$(nmap -p "$PORT" --script ssl-enum-ciphers "$HOST" 2>/dev/null)

# Uncomment the line below if you want to see the full raw output:
# echo "$OUTPUT"

# Track whether insecure protocols are present and whether TLS 1.2 or 1.3 is supported
insecure_protocol_found="false"
supports_tls12="false"
supports_tls13="false"

# Read the Nmap output line by line
while IFS= read -r line; do
  # Detect SSLv3
  if [[ "$line" =~ "SSLv3" ]]; then
    insecure_protocol_found="true"
  fi
  # Detect TLS 1.0
  if [[ "$line" =~ "TLSv1.0" ]]; then
    insecure_protocol_found="true"
  fi
  # Detect TLS 1.1
  if [[ "$line" =~ "TLSv1.1" ]]; then
    insecure_protocol_found="true"
  fi
  # Detect TLS 1.2
  if [[ "$line" =~ "TLSv1.2" ]]; then
    supports_tls12="true"
  fi
  # Detect TLS 1.3
  if [[ "$line" =~ "TLSv1.3" ]]; then
    supports_tls13="true"
  fi
done <<< "$OUTPUT"

# Print a summary of which protocols were found
echo "===== Nmap SSL/TLS Scan Summary ====="
if [[ "$insecure_protocol_found" == "true" ]]; then
  echo "- Insecure protocols detected (SSLv3, TLS 1.0, or TLS 1.1)."
else
  echo "- No insecure protocols detected."
fi

if [[ "$supports_tls12" == "true" ]]; then
  echo "- TLS 1.2 is supported."
fi

if [[ "$supports_tls13" == "true" ]]; then
  echo "- TLS 1.3 is supported."
fi
echo "====================================="

# PCI DSS 4.0 compliance check logic
# FAIL if SSLv3/TLS 1.0/TLS 1.1 is supported
if [[ "$insecure_protocol_found" == "true" ]]; then
  echo "PCI DSS 4.0 Check: FAIL"
  echo "Reason: Insecure protocol(s) enabled (SSLv3/TLS1.0/TLS1.1)."
  exit 1
fi

# FAIL if neither TLS 1.2 nor TLS 1.3 is supported
if [[ "$supports_tls12" == "false" && "$supports_tls13" == "false" ]]; then
  echo "PCI DSS 4.0 Check: FAIL"
  echo "Reason: Server does not support TLS 1.2 or higher."
  exit 1
fi

# Otherwise PASS
echo "PCI DSS 4.0 Check: PASS"
exit 0
