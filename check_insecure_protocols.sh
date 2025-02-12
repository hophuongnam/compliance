#!/usr/bin/env bash
#
# check_insecure_protocols.sh
#
# Usage: ./check_insecure_protocols.sh <HOSTNAME_OR_IP> <PORT>
#
# This script attempts to connect to a server with different SSL/TLS versions
# to see which are supported. It then determines a PASS/FAIL status according
# to simplified PCI DSS 4.0 protocol rules:
#   - FAIL if SSLv3, TLS 1.0, or TLS 1.1 is supported.
#   - FAIL if neither TLS 1.2 nor TLS 1.3 is supported.
#   - Otherwise PASS.

HOST="$1"
PORT="$2"

# Usage/help check
if [[ -z "$HOST" || -z "$PORT" ]]; then
  echo "Usage: $0 <HOST> <PORT>"
  echo "Example: $0 example.com 443"
  exit 1
fi

# Variables to track whether each protocol is supported
ssl3_supported=false
tls10_supported=false
tls11_supported=false
tls12_supported=false
tls13_supported=false

# A function to check a specific protocol
# and set a variable if it is supported.
check_protocol() {
  local protocol_flag="$1"
  local protocol_name="$2"
  local supported_var="$3"

  echo -n "Checking $protocol_name ... "

  # Attempt the handshake; look for "New," or "Cipher is"
  # which indicates a successful handshake.
  local output
  output=$(echo | openssl s_client \
    -connect "$HOST:$PORT" \
    "$protocol_flag" \
    -servername "$HOST" \
    -quiet 2>&1)

  if echo "$output" | grep -q -E "New,|Cipher is"; then
    # Mark that protocol as supported
    eval "$supported_var=true"
    echo "SUPPORTED"
  else
    echo "NOT supported"
  fi
}

# Check each protocol individually
check_protocol "-ssl3"  "SSLv3"    "ssl3_supported"
check_protocol "-tls1"  "TLS 1.0"  "tls10_supported"
check_protocol "-tls1_1" "TLS 1.1" "tls11_supported"
check_protocol "-tls1_2" "TLS 1.2" "tls12_supported"
check_protocol "-tls1_3" "TLS 1.3" "tls13_supported"

# Evaluate compliance according to simplified PCI DSS 4.0 rules:
# 1) Server must NOT support SSLv3, TLS 1.0, or TLS 1.1.
# 2) Server must support at least TLS 1.2 or TLS 1.3.

# If any insecure protocols are supported => FAIL
if [ "$ssl3_supported" = "true" ] || \
   [ "$tls10_supported" = "true" ] || \
   [ "$tls11_supported" = "true" ]; then
  echo "======================================================"
  echo "PCI DSS 4.0 Compliance Check: FAIL"
  echo "Reason: Insecure protocol(s) enabled (SSLv3/TLS1.0/TLS1.1)."
  echo "======================================================"
  exit 1
fi

# If neither TLS 1.2 nor TLS 1.3 is supported => FAIL
if [ "$tls12_supported" = "false" ] && [ "$tls13_supported" = "false" ]; then
  echo "======================================================"
  echo "PCI DSS 4.0 Compliance Check: FAIL"
  echo "Reason: Server does not support TLS 1.2 or higher."
  echo "======================================================"
  exit 1
fi

# Otherwise => PASS
echo "======================================================"
echo "PCI DSS 4.0 Compliance Check: PASS"
echo "All insecure protocols disabled; TLS 1.2 or higher is enabled."
echo "======================================================"
exit 0
