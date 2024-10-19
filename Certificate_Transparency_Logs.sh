#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 [-o output_file] [-v] <domain>"
    echo "  -o output_file   Save results to the specified output file."
    echo "  -v               Enable verbose mode."
    exit 1
}

# Check if a domain is provided
if [ "$#" -lt 1 ]; then
    usage
fi

# Default values
OUTPUT_FILE=""
VERBOSE=false

# Parse command line options
while getopts "o:v" opt; do
    case $opt in
        o)
            OUTPUT_FILE="$OPTARG"
            ;;
        v)
            VERBOSE=true
            ;;
        *)
            usage
            ;;
    esac
done

shift $((OPTIND - 1))

DOMAIN=$1

# Validate the domain format using a simple regex
if ! [[ $DOMAIN =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "Error: Invalid domain format."
    exit 1
fi

# Define user-agent to use with curl for querying crt.sh
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3"

# Query crt.sh for subdomains & clean up the output
if [ "$VERBOSE" = true ]; then
    echo "Enumerating subdomains for $DOMAIN from crt.sh..."
fi

# Execute the curl command and handle errors
if output=$(curl -s -A "$USER_AGENT" "https://crt.sh/?q=%.$DOMAIN&output=json"); then
    # Extract and clean subdomains
    SUBDOMAINS=$(echo "$output" | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u)

    # Count unique subdomains
    COUNT=$(echo "$SUBDOMAINS" | wc -l)

    # Display the results
    if [ "$VERBOSE" = true ]; then
        echo "Found $COUNT unique subdomains:"
        echo "$SUBDOMAINS"
    else
        echo "$SUBDOMAINS"
    fi

    # Save to output file if specified
    if [ -n "$OUTPUT_FILE" ]; then
        echo "$SUBDOMAINS" > "$OUTPUT_FILE"
        echo "Results saved to $OUTPUT_FILE."
    fi
else
    echo "Failed to fetch data from crt.sh."
    exit 1
fi

# Optionally fetch SSL certificate info
read -p "Do you want to fetch SSL certificate information for these subdomains? (y/n): " FETCH_SSL
if [[ $FETCH_SSL =~ ^[Yy]$ ]]; then
    echo "Fetching SSL certificate information..."
    while read -r subdomain; do
        echo "Fetching for: $subdomain"
        curl -s -A "$USER_AGENT" "https://crt.sh/?id=$(curl -s -A "$USER_AGENT" "https://crt.sh/?q=$subdomain&output=json" | jq -r '.[].id')" | jq -r '.[].name_value'
    done <<< "$SUBDOMAINS"
fi

echo "Enumeration complete."

