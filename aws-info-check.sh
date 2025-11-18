#!/bin/bash
input_file="ou_info.conf"

if [[ ! -f "$input_file" ]]; then
  echo "File not found!"
  exit 1
fi

while IFS= read -r line || [[ -n "$line" ]]; do
  ou_id=$(echo "$line" | cut -d':' -f3)
  ou_name=$(echo "$line" | cut -d':' -f1)

  accounts=$(aws organizations list-accounts-for-parent --parent-id "$ou_id" --output text --query 'Accounts[*].[Id,Name]')

  if [[ -z "$accounts" ]]; then
    echo "No accounts found in OU \"${ou_name}\""
    continue
  fi

  echo "Org $ou_name"
  echo ""
  echo "Here is the list of AWS accounts in the OU $ou_id \"${ou_name}\""
  echo "-----------------------------------------------------------------------------------"
  echo "| Account Name                                   | Account ID      | OU Name|OU ID|"
  echo "|------------------------------------------------|-----------------|--------|-----|"
  echo "$accounts" | awk -F'\t' -v ou_name="$ou_name" -v ou_id="$ou_id" '{printf "| %-46s | %-15s | %-15s |%-15s|\n", $2, $1, ou_name, ou_id}'
  echo "----------------------------------------------------------------------------------------------------"
  echo ""
done < "$input_file"
