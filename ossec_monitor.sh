#!/bin/bash

# Script to extract and display monitored directories from OSSEC's ossec.conf.

# Default OSSEC configuration file path.  Modify if yours is different.
OSSEC_CONF="/var/ossec/etc/ossec.conf"

# Function to check if OSSEC config file exists
check_ossec_conf() {
  if [ ! -f "$OSSEC_CONF" ]; then
    echo "Error: OSSEC configuration file not found at $OSSEC_CONF"
    exit 1
  fi
}

# Function to extract and display directories
extract_directories() {
  echo "Monitored Directories (from $OSSEC_CONF):"
  echo "--------------------------------------------"

  # Use awk to find the <syscheck> section and extract <directories> tags.
  # This handles multi-line configurations and attributes more robustly.
  awk '/<syscheck>/,/<\/syscheck>/ {
      if ($0 ~ /<directories/) {
          # Extract directory path and attributes
          gsub(/.*<directories /, "", $0);
          gsub(/ *>/, "", $0);  # Remove closing >
          # Find matching closing tag on potentially the same line
          if ( match($0, /<\/directories>/ ) ) {
              dir_line=substr($0, 1, RSTART-1);
              print "Directory: " dir_line;
          }
      }
  }' "$OSSEC_CONF" |
  while IFS= read -r line; do
      echo "$line"
  done
  echo ""

}

# Function to extract and display ignored paths/files
extract_ignored() {
  echo "Ignored Paths/Files (from $OSSEC_CONF):"
  echo "-----------------------------------------"

    awk '/<syscheck>/,/<\/syscheck>/ {
      if ($0 ~ /<ignore/) {
        gsub(/.*<ignore/, "", $0);  #remove everything before tag
        gsub(/<\/ignore>.*/, "", $0); #remove everything after tag
        gsub(/>/, "",$0) # remove any leftover ">"
        print $0;
      }
  }' "$OSSEC_CONF"

  echo ""
}

# Function to extract and display nodiff files
extract_nodiff() {
  echo "NoDiff Files (from $OSSEC_CONF):"
  echo "-----------------------------------------"

    awk '/<syscheck>/,/<\/syscheck>/ {
      if ($0 ~ /<nodiff/) {
        gsub(/.*<nodiff/, "", $0);  #remove everything before tag
        gsub(/<\/nodiff>.*/, "", $0); #remove everything after tag
        gsub(/>/, "",$0) # remove any leftover ">"
        print $0;
      }
  }' "$OSSEC_CONF"
  echo ""
}



# Main script execution
check_ossec_conf
extract_directories
extract_ignored
extract_nodiff

exit 0
