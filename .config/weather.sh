#!/bin/bash

# Use the first argument as location, default to "WADS" if none is given
LOCATION="${1:-WADS}"

if ping -c 1 -W 1 wttr.in &> /dev/null; then
    curl -s "wttr.in/${LOCATION}?format=1" | sed 's/[^0-9+°C-]//g'
else
    echo "N/A"
fi
