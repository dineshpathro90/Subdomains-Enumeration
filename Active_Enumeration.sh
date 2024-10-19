#!/bin/bash

# Enhanced active enumeration script using naabu and nmap
# Advanced techniques added for flexibility and efficiency

# Function to display help message
usage() {
    echo "Usage: $0 [OPTIONS] <target_domain_or_IP>"
    echo
    echo "Options:"
    echo "  -h, --help        Show this help message and exit."
    echo "  -o, --output DIR  Specify a custom output directory."
    echo "  -p, --ports PORTS Comma-separated ports to scan (default: fast scan with naabu)."
    echo "  -n, --nmap-flags  Custom nmap flags for detailed scan (default: -sV)."
    echo "  -c, --concurrent  Run scans concurrently for faster enumeration."
    echo
    echo "Example:"
    echo "  $0 -o /tmp/scan-results example.com"
    exit 0
}

# Default options
OUTPUT_DIR=$(mktemp -d -t enum-XXXXXXXXXX)  # Temporary directory by default
CUSTOM_PORTS=""                              # No custom ports by default
NMAP_FLAGS="-sV"                             # Default nmap flags
CONCURRENT=false                             # No concurrency by default

# Argument parsing
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -h|--help) usage ;;
        -o|--output) OUTPUT_DIR="$2"; shift 2 ;;
        -p|--ports) CUSTOM_PORTS="$2"; shift 2 ;;
        -n|--nmap-flags) NMAP_FLAGS="$2"; shift 2 ;;
        -c|--concurrent) CONCURRENT=true; shift ;;
        --) shift; break ;;
        -*|--*) echo "Unknown option: $1" ; exit 1 ;;
        *) TARGET="$1"; shift ;;
    esac
done

# Check if a target domain/IP was provided
if [ -z "$TARGET" ]; then
    echo "Error: Missing target domain or IP."
    echo "Use '$0 --help' for more information."
    exit 1
fi

echo "[*] Output files will be saved in $OUTPUT_DIR"

# Function to perform fast port scanning with naabu
perform_naabu_scan() {
    echo "[*] Performing fast port scan with naabu on $TARGET..."
    naabu -host "$TARGET" -o "$OUTPUT_DIR/naabu_output.txt" -silent
    # Extract open ports from naabu output
    OPEN_PORTS=$(awk -F ":" '{print $2}' "$OUTPUT_DIR/naabu_output.txt" | tr '\n' ',' | sed 's/,$//')
    if [ -z "$OPEN_PORTS" ]; then
        echo "No open ports found with naabu. Exiting."
        exit 1
    fi
    echo "[*] Found open ports: $OPEN_PORTS"
}

# Function to perform detailed nmap scanning
perform_nmap_scan() {
    local ports="$1"
    echo "[*] Performing detailed scan with nmap on discovered ports..."
    nmap -p "$ports" "$NMAP_FLAGS" "$TARGET" -oN "$OUTPUT_DIR/nmap_detailed_scan.txt"
}

# Run scans concurrently if --concurrent is set
if [ "$CONCURRENT" = true ]; then
    if [ -n "$CUSTOM_PORTS" ]; then
        # Perform custom port scan in the background
        (perform_nmap_scan "$CUSTOM_PORTS") &
    else
        # Run naabu scan and nmap scan concurrently
        perform_naabu_scan &
        wait
        perform_nmap_scan "$OPEN_PORTS" &
    fi
    wait
else
    # Sequential execution
    if [ -n "$CUSTOM_PORTS" ]; then
        echo "[*] Using custom ports: $CUSTOM_PORTS"
        perform_nmap_scan "$CUSTOM_PORTS"
    else
        perform_naabu_scan
        perform_nmap_scan "$OPEN_PORTS"
    fi
fi

# Optionally add banner grabbing using netcat or nmap's --script option
banner_grabbing() {
    echo "[*] Grabbing banners from open ports..."
    for port in $(echo "$OPEN_PORTS" | tr ',' ' '); do
        nc -vz "$TARGET" "$port" 2>&1 | tee -a "$OUTPUT_DIR/banner_grabbing.txt"
    done
}

# Uncomment if you want to include banner grabbing
# banner_grabbing

echo "[*] Enumeration completed. Check $OUTPUT_DIR for detailed scan results."

# Optional Cleanup: Uncomment the following line if you want to delete the output directory after scanning
# rm -rf "$OUTPUT_DIR"

