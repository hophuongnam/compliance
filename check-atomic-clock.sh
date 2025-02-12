#!/usr/bin/env bash
#
# check-atomic-clock.sh
#
# Checks if the system is using ntpd or chrony, finds the active time source,
# and reports if it is a stratum-1 (“atomic clock”) source.
#

#####################################
# Helper functions
#####################################

check_ntp() {
  echo "Detected NTP (ntpd) is running."

  # Grab the stratum from the current system variables
  # 'ntpq -c rv' outputs something like: "associd=0 status=0618 ... stratum=2 ..."
  local stratum
  stratum=$(ntpq -c rv 2>/dev/null | sed -n 's/.*stratum=\([0-9]\+\).*/\1/p')

  if [[ -z "$stratum" ]]; then
    echo "Could not determine stratum from ntpd."
    return
  fi

  # If stratum is 1, we generally assume it’s an atomic clock or GPS reference.
  if [[ "$stratum" == "1" ]]; then
    echo "The system is synchronized to a stratum-1 (atomic/GPS) source."
  else
    echo "The system is synchronized to stratum $stratum (not a direct atomic clock)."
  fi

  echo
  echo "Detailed NTP peer status (ntpq -p):"
  ntpq -p
}

check_chrony() {
  echo "Detected Chrony is running."

  # We can parse chronyc tracking output for stratum info:
  # Example output (snippet):
  #   Reference ID    : 203.0.113.10 (time.example.org)
  #   Stratum         : 1
  local stratum
  stratum=$(chronyc tracking 2>/dev/null | awk '/Stratum/ {print $3}')

  if [[ -z "$stratum" ]]; then
    echo "Could not determine stratum from chrony."
    return
  fi

  if [[ "$stratum" == "1" ]]; then
    echo "The system is synchronized to a stratum-1 (atomic/GPS) source."
  else
    echo "The system is synchronized to stratum $stratum (not a direct atomic clock)."
  fi

  echo
  echo "Detailed Chrony sources (chronyc sources -v):"
  chronyc sources -v
}

#####################################
# Main Script
#####################################

# 1. Check if chrony is active
if systemctl is-active --quiet chrony; then
  check_chrony
# 2. Otherwise check if ntpd is active
elif systemctl is-active --quiet ntp; then
  check_ntp
elif systemctl is-active --quiet ntpd; then
  # Some distros/services use 'ntpd' directly
  check_ntp
else
  echo "Neither chrony nor ntpd appears to be running. Cannot check NTP status."
  exit 1
fi
