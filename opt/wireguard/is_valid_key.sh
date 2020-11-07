#!/bin/bash
set -eEu -o pipefail

# Create variable for parameter
KEY=$1
# If KEY references a file, then read file into KEY
[ -e "$KEY" ] && KEY=$(cat $KEY)
# If KEY matches regular expression for 44 byte base64 string
[[ "$KEY" =~ ^[0-9a-zA-Z/+]{43}=$ ]]
# Exit with boolean results from test
exit $?
