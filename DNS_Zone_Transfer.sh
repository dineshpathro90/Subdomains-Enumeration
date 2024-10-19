#!/bin/bash
\# Comprehensive DNS Zone Transfer check using multiple tools.

if \[ "$#" -ne 2 \]; then

    echo "Usage: $0 <Domain> <DNS Server>"

    exit 1

fi

DOMAIN\=$1

DNSSERVER\=$2

TIMESTAMP\=$(date +%Y%m%d\-%H%M%S)

OUTPUT\_DIR\="DNS\_Zone\_Transfer\_$TIMESTAMP"

mkdir -p $OUTPUT\_DIR

\# Function to perform DNS Zone Transfer using dig

function check\_dig {

    echo "1. Using dig for DNS Zone Transfer..."

    dig @$DNSSERVER $DOMAIN AXFR > "$OUTPUT\_DIR/dig\_$DOMAIN.txt"

    echo "Done. Output saved to $OUTPUT\_DIR/dig\_$DOMAIN.txt"

    echo "---------------------------------------------------------------------"

}

 
\# Function to perform DNS Zone Transfer using host

function check\_host {

    echo "2. Using host for DNS Zone Transfer..."

    host -l $DOMAIN $DNSSERVER > "$OUTPUT\_DIR/host\_$DOMAIN.txt"

    echo "Done. Output saved to $OUTPUT\_DIR/host\_$DOMAIN.txt"

    echo "---------------------------------------------------------------------"

}

\# Function to perform DNS Zone Transfer using nslookup

function check\_nslookup {

    echo "3. Using nslookup for DNS Zone Transfer..."

    echo -e "server $DNSSERVER\\nls -d $DOMAIN" | nslookup > "$OUTPUT\_DIR/nslookup\_$DOMAIN.txt"

    echo "Done. Output saved to $OUTPUT\_DIR/nslookup\_$DOMAIN.txt"

    echo "---------------------------------------------------------------------"

}

# Running all checks

echo "DNS Zone Transfer checks for $DOMAIN using server $DNSSERVER..."

echo "====================================================================="

check\_dig

check\_host

check\_nslookup

echo "All checks complete. Review the outputs in the $OUTPUT\_DIR directory."
