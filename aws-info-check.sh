#!/bin/bash
input_file="ou_prod.conf"

# Check if the file exists
if [[ ! -f "$input_file" ]]; then
  echo "File not found!"
  exit 1
fi

# Read the file line by line
while IFS= read -r line
do
  ou_id=$(echo "$line" | cut -d':' -f3)
  ou_name=$(echo "$line" | cut -d':' -f1)
  accounts=$(aws organizations list-accounts-for-parent --parent-id ${ou_id} --output text --query 'Accounts[*].[Id,Name]')
  if [[ -z "$accounts" ]]; then
    echo "No accounts found in OU \"${ou_name}\""
    continue
  fi
  echo ""
  echo "Here is the list of AWS accounts in the OU \"${ou_name}\""
  echo "--------------------------------------------------------------------"
  echo "| Account Name                                   | Account ID      |"
  echo "|------------------------------------------------|-----------------|"
  echo "$accounts" | awk -F'\t' '{printf "| %-46s | %-15s |\n", $2, $1}'
  echo "--------------------------------------------------------------------"
  echo ""
done < "$input_file"