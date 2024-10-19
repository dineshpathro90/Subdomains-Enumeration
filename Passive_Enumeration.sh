#!/bin/bash

# Enhanced Passive Enumeration Bash Script with Advanced Techniques

# Function to display help information
function display_help() {
    echo "Usage: $0 [options]"
    echo
    echo "This script performs enhanced passive enumeration on a target domain."
    echo
    echo "Options:"
    echo "  -h, --help          Display this help message"
    echo "  -d, --domain        Specify the target domain"
    echo "  -o, --output-dir    Specify the output directory (default is current directory)"
    echo
    echo "Example:"
    echo "  $0 -d example.com -o /path/to/output"
    exit 0
}

# Function to check if a command exists
function check_command() {
    command -v "$1" >/dev/null 2>&1 || {
        echo >&2 "Error: $1 is not installed."
        read -p "Do you want to install it? (y/n): " install_choice
        if [[ $install_choice =~ ^[Yy]$ ]]; then
            sudo apt-get install "$1"
        else
            exit 1
        fi
    }
}

# Function to gather DNS records
function gather_dns_records() {
    echo "Gathering DNS records..."
    dig @$targetDomain ANY +noall +answer
}

# Function to enumerate subdomains with various tools
function enumerate_subdomains() {
    echo "Enumerating subdomains..."

    # Subdomain enumeration with Subfinder
    echo "Enumerating subdomains with Subfinder..."
    if subfinder -d "$targetDomain" -o "$outputDir/subfinder_subs.txt"; then
        echo "Subfinder results saved to $outputDir/subfinder_subs.txt"
    else
        echo "Subfinder encountered an error."
    fi

    # Subdomain enumeration with Sublist3r
    echo "Enumerating subdomains with Sublist3r..."
    if sublist3r -d "$targetDomain" -o "$outputDir/sublist3r_subs.txt"; then
        echo "Sublist3r results saved to $outputDir/sublist3r_subs.txt"
    else
        echo "Sublist3r encountered an error."
    fi

    # Subdomain enumeration with Knockpy
    echo "Enumerating subdomains with Knockpy..."
    if knockpy "$targetDomain" -o "$outputDir/knockpy_subs.csv"; then
        echo "Knockpy results saved to $outputDir/knockpy_subs.csv"
    else
        echo "Knockpy encountered an error."
    fi

    # Brute forcing subdomains with a wordlist
    echo "Brute forcing subdomains with a wordlist..."
    if [ -f "$outputDir/subdomain_wordlist.txt" ]; then
        dnsx -l "$outputDir/subdomain_wordlist.txt" -d "$targetDomain" -o "$outputDir/brute_force_subs.txt"
        echo "Brute-forced subdomains saved to $outputDir/brute_force_subs.txt"
    else
        echo "Wordlist for brute forcing not found. Please provide a wordlist as 'subdomain_wordlist.txt' in the output directory."
    fi
}

# Function to perform reverse DNS lookups
function reverse_dns_lookup() {
    echo "Performing reverse DNS lookup on found IPs..."
    if [ -f "$outputDir/brute_force_subs.txt" ]; then
        cat "$outputDir/brute_force_subs.txt" | awk '{print $2}' | sort -u | xargs -I {} dig -x {} +short >> "$outputDir/reverse_dns.txt"
        echo "Reverse DNS lookups saved to $outputDir/reverse_dns.txt"
    else
        echo "No subdomains found to perform reverse DNS lookups."
    fi
}

# Function to fetch historical data from the Wayback Machine
function fetch_wayback_data() {
    echo "Searching Wayback Machine for historical data..."
    if wget -O "$outputDir/wayback_data.txt" "https://web.archive.org/cdx/search/cdx?url=*$targetDomain*&output=text"; then
        echo "Historical data saved to $outputDir/wayback_data.txt"
    else
        echo "Failed to retrieve Wayback Machine data."
    fi
}

# Function to summarize results
function summarize_results() {
    echo "Summary of Results:"
    echo "-------------------"
    for tool in subfinder sublist3r knockpy; do
        count=$(wc -l < "$outputDir/${tool}_subs.txt" 2>/dev/null || echo "0")
        echo "$tool found $count subdomains."
    done
    echo "Wayback Machine data retrieved and saved."
}

# Main script execution
# Check for help option
if [[ "$#" -eq 0 ]]; then
    display_help
fi

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) display_help ;;
        -d|--domain) shift; targetDomain="$1" ;;
        -o|--output-dir) shift; outputDir="$1" ;;
        *) echo "Unknown parameter passed: $1"; display_help ;;
    esac
    shift
done

# Default output directory if none specified
outputDir=${outputDir:-"."}

# Create output directory if it doesn't exist
mkdir -p "$outputDir"

# Check for necessary commands
check_command "dig"
check_command "subfinder"
check_command "sublist3r"
check_command "knockpy"
check_command "wget"
check_command "dnsx"

echo "Performing enhanced passive enumeration on $targetDomain"

# Gather DNS records
gather_dns_records

# Subdomain enumeration
enumerate_subdomains

# Perform reverse DNS lookup
reverse_dns_lookup

# Fetch historical data
fetch_wayback_data

# Summarize results
summarize_results

# Display completion message
echo "Enhanced passive enumeration completed successfully."

