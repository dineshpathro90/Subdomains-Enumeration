#!/bin/bash

# Script for brute-force subdomain enumeration using Fierce

# Ensure the user provides a domain name to scan
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

DOMAIN=$1

# Specify a wordlist. Adjust the path according to your setup.
# You can find numerous wordlists in tools like SecLists (https://github.com/danielmiessler/SecLists)
WORDLIST="/root/dir_wordlist.txt"

# Check if the wordlist exists
if [ ! -f "$WORDLIST" ]; then
    echo "Error: Wordlist not found at $WORDLIST"
    exit 1
fi

echo "Starting brute-force subdomain enumeration for $DOMAIN using Fierce"
echo "This might take a while..."

# Run Fierce without --wordlist. Use --subdomain-file instead to specify the wordlist.
fierce --domain "$DOMAIN" --subdomain-file "$WORDLIST" --delay 3

echo "Enumeration completed."
echo "Check out more payloads [here](https://github.com/danielmiessler/SecLists/tree/master/Discovery/DNS)."

# Instructions for saving and executing the script
echo "Save the bash script as '_name.sh_' and then give executable rights using 'chmod +x name.sh'."

