#!/bin/bash

# Function to display help information
function show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "This script scans for subdomains of a given target domain."
    echo
    echo "Options:"
    echo "  -h, --help        Display this help message."
    echo "  -d, --domain      Specify the target domain (e.g., example.com)."
    echo
    echo "Examples:"
    echo "  $0 -d example.com"
    echo "  $0 --domain example.com"
    exit 0
}

# Check for command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -d|--domain)
            target="$2"
            shift # Move to the next argument
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            ;;
    esac
    shift # Move to the next argument
done

# If no domain is provided, prompt the user
if [ -z "$target" ]; then
    read -p "Enter target domain (e.g., example.com): " target
fi

# Remove temporary files (if any) silently
rm -f subdomain_scan_tmp1.txt subdomain_scan_tmp.txt &> /dev/null

# Extract the first part of the domain (without TLD)
sfe=$(echo "$target" | cut -d "." -f 1)

# Set a loop duration (adjust as needed)
runtime="40 seconds"
endtime=$(date -ud "$runtime" +%s)

# Loop for the specified duration
while [[ $(date -u +%s) -le $endtime ]]; do
    # Start with "www" subdomain
    echo -n "+-www" > subdomain_scan_tmp.txt

    # Loop through common subdomain prefixes (add more as needed)
    for prefix in mail ftp blog shop; do
        potential_subdomain="$prefix.$target"

        # Check if the subdomain resolves to an IP (basic validation)
        if host -t A "$potential_subdomain" &> /dev/null; then
            echo "+-$potential_subdomain" >> subdomain_scan_tmp.txt
        fi
    done

    # Use Google search for additional discovery (limited accuracy)
    # Be aware of Google's terms of service
    search_url="https://www.google.com/search?q=site:$target"
    user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64)"

    # Download search results silently and filter for potential subdomains
    potential_subdomains=$(curl -s -A "$user_agent" "$search_url" | grep -Eo "(http|https)://[^/]+" | grep -i "$target")

    # Extract subdomain names and remove duplicates
    for subdomain in $potential_subdomains; do
        subdomain_name=$(echo "$subdomain" | cut -d '/' -f 3 | cut -d '.' -f 1)
        if [[ "$subdomain_name" != "$sfe" ]]; then
            echo "+-$subdomain_name" >> subdomain_scan_tmp.txt
        fi
    done

    # Sort and remove duplicates from the temporary file
    sort -u subdomain_scan_tmp.txt | sed 's/^/+-/' > subdomain_scan_tmp1.txt

    # Move temporary file content to the main temporary file
    mv subdomain_scan_tmp1.txt subdomain_scan_tmp.txt
done

# Print discovered subdomains (remove leading "+" sign)
sed 's/^+//' subdomain_scan_tmp.txt

# Remove temporary files again
rm -f subdomain_scan_tmp1.txt subdomain_scan_tmp.txt

