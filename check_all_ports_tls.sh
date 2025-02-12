#!/usr/bin/env bash
#
# check_all_ports_tls.sh
#
# Usage: ./check_all_ports_tls.sh <HOST>
#
# This script:
#   1. Scans all TCP ports on <HOST> to find open ports.
#   2. Flags if any known-insecure plaintext service is open (e.g., HTTP on port 80).
#   3. Runs ssl-enum-ciphers on ports that *might* support TLS to detect SSL/TLS versions.
#   4. Flags if any insecure TLS protocol (SSLv3, TLS 1.0, TLS 1.1) is found.
#   5. Flags if no open port offers TLS 1.2 or higher.
#   6. Outputs PASS/FAIL for **simplified** PCI DSS 4.0 checks.

HOST="$1"

if [[ -z "$HOST" ]]; then
  echo "Usage: $0 <HOST>"
  echo "Example: $0 example.com"
  exit 1
fi

echo "======================================================"
echo "Scanning all TCP ports on: $HOST"
echo "This may take some time..."
echo "======================================================"

# 1) Perform a TCP port scan on all ports (1-65535).
#    -T4 speeds up the timing; adjust as needed.
#    --open shows only open ports in the output.
#    -oG outputs in a "grepable" format for easier parsing.
PORT_SCAN_OUTPUT=$(nmap -p- -T4 --open "$HOST" -oG - 2>/dev/null)

# Extract open port numbers and store them
OPEN_PORTS=()
# Also map each port number to the detected service name (if any)
declare -A PORT_TO_SERVICE

while IFS= read -r line; do
  # We look for lines that contain "Ports:" which list open ports
  if [[ "$line" =~ Ports: ]]; then
    # Example line: "Host: 93.184.216.34 ()  Ports: 80/open/tcp//http///, 443/open/tcp//https///"
    # We'll extract the part after "Ports: "
    ports_str=$(echo "$line" | sed 's/.*Ports: //')
    IFS=',' read -ra ports_array <<< "$ports_str"
    for port_info in "${ports_array[@]}"; do
      # port_info might be something like "80/open/tcp//http///"
      # We'll split on '/' and parse out the port number and service
      port_num=$(echo "$port_info" | awk -F'/' '{print $1}')
      service_name=$(echo "$port_info" | awk -F'/' '{print $5}')

      OPEN_PORTS+=("$port_num")
      PORT_TO_SERVICE["$port_num"]="$service_name"
    done
  fi
done <<< "$PORT_SCAN_OUTPUT"

# Check if we found any open ports
if [[ ${#OPEN_PORTS[@]} -eq 0 ]]; then
  echo "No open TCP ports detected on $HOST."
  echo "PCI DSS 4.0 Check: PASS (No services to test)."
  exit 0
fi

echo "Open ports on $HOST: ${OPEN_PORTS[*]}"
echo
echo "Service detection (from initial Nmap scan):"
for p in "${OPEN_PORTS[@]}"; do
  echo "  Port $p => ${PORT_TO_SERVICE[$p]}"
done
echo "======================================================"

# 2) Check for known insecure plaintext services (e.g., HTTP on port 80).
#    If you want to add more (FTP, Telnet, etc.), list them here.
insecure_plaintext_found="false"

# Example of known-insecure plaintext services (feel free to expand this list):
#  - http (generally on port 80)
#  - ftp (21), telnet (23), pop3 (110), imap (143), etc.
#    The script checks the service name Nmap identifies, not just the port number.
PLAINTEXT_SERVICES=("http" "ftp" "telnet" "pop3" "imap" "smtp" "ldap" "rdp") 
# ^ RDP actually supports encryption, but older versions can be insecure. 
#   Adjust for your environment's needs.

for p in "${OPEN_PORTS[@]}"; do
  service_name="${PORT_TO_SERVICE[$p]}"
  # Normalize to lowercase (in case of weird capitalization)
  service_name_lower=$(echo "$service_name" | tr '[:upper:]' '[:lower:]')

  for insecure_svc in "${PLAINTEXT_SERVICES[@]}"; do
    if [[ "$service_name_lower" == *"$insecure_svc"* ]]; then
      # Found a known plaintext or insecure service
      insecure_plaintext_found="true"
      echo "WARNING: Found insecure/plaintext service '$service_name' on port $p."
    fi
  done
done

# 3) For SSL/TLS checks, we'll run ssl-enum-ciphers only if it's likely an SSL/TLS service
#    i.e., we see "https", "ssl", or something relevant. However, you can brute force
#    by checking ANY open port. We'll do a compromise: check all open ports, but Nmap
#    will skip if it doesn't detect SSL/TLS anyway.
found_insecure_protocol="false"
found_tls12_or_higher="false"

echo
echo "Running ssl-enum-ciphers on each open port to detect SSL/TLS versions..."
for port in "${OPEN_PORTS[@]}"; do
  echo "------------------------------------------------------"
  echo "Port $port => Service: ${PORT_TO_SERVICE[$port]}"
  
  # Run Nmap ssl-enum-ciphers for this port
  nmap_output=$(nmap -sV --script=ssl-enum-ciphers -p "$port" "$HOST" 2>/dev/null)
  
  echo "$nmap_output"

  # Parse the output line by line
  while IFS= read -r line; do
    # Detect SSLv3
    if [[ "$line" =~ "SSLv3" ]]; then
      found_insecure_protocol="true"
    fi
    # Detect TLSv1.0
    if [[ "$line" =~ "TLSv1.0" ]]; then
      found_insecure_protocol="true"
    fi
    # Detect TLSv1.1
    if [[ "$line" =~ "TLSv1.1" ]]; then
      found_insecure_protocol="true"
    fi
    # If we see TLSv1.2 or TLSv1.3, mark that as found
    if [[ "$line" =~ "TLSv1.2" ]] || [[ "$line" =~ "TLSv1.3" ]]; then
      found_tls12_or_higher="true"
    fi
  done <<< "$nmap_output"
done

echo "======================================================"
echo "Summary of Findings:"
echo " - Insecure plaintext services detected? $insecure_plaintext_found"
echo " - Insecure TLS protocols (SSLv3/TLS1.0/TLS1.1) detected? $found_insecure_protocol"
echo " - TLS 1.2 or 1.3 detected on at least one port? $found_tls12_or_higher"
echo "======================================================"

# 4) Evaluate simplified PCI DSS 4.0 compliance logic

# A) If any insecure plaintext service is found => FAIL.
#    Because PCI DSS requires encrypted transmission for cardholder data.
if [[ "$insecure_plaintext_found" == "true" ]]; then
  echo "PCI DSS 4.0 Check: FAIL"
  echo "Reason: Insecure plaintext service(s) open (e.g., HTTP on port 80)."
  echo "      If this is only for a redirect to HTTPS and not handling CHD, investigate carefully."
  exit 1
fi

# B) If any insecure protocol is found => FAIL
if [[ "$found_insecure_protocol" == "true" ]]; then
  echo "PCI DSS 4.0 Check: FAIL"
  echo "Reason: Insecure SSL/TLS protocol(s) detected (SSLv3, TLS 1.0, or TLS 1.1)."
  exit 1
fi

# C) If no TLS 1.2 or higher is supported => FAIL
if [[ "$found_tls12_or_higher" == "false" ]]; then
  echo "PCI DSS 4.0 Check: FAIL"
  echo "Reason: No open port supports TLS 1.2 or higher."
  exit 1
fi

# Otherwise => PASS
echo "PCI DSS 4.0 Check: PASS"
echo "All discovered services either do not use TLS or properly support TLS 1.2/1.3."
echo "No insecure plaintext services appear to be serving cardholder data."
exit 0
