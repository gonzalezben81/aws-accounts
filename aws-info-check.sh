#!/bin/bash
input_file="ou_info.conf"
csv_file="org_units_accounts.csv"
md_file="accounts.md"

# Check if the file exists
if [[ ! -f "$input_file" ]]; then
  echo "File not found!"
  exit 1
fi

# Initialize CSV and Markdown files
echo "Account Name,Account ID,OU Name,OU ID" > "$csv_file"

cat > "$md_file" <<EOF
# AWS Accounts by OU

EOF

# Read the file line by line
while IFS= read -r line ; do
  ou_id=$(echo "$line" | cut -d':' -f3)
  ou_name=$(echo "$line" | cut -d':' -f1)

  accounts=$(aws organizations list-accounts-for-parent --parent-id "$ou_id" --output text --query 'Accounts[*].[Id,Name]')

  if [[ -z "$accounts" ]]; then
    echo "No accounts found in OU \"$ou_name\""
    continue
  fi

  # --- Print to console ---
  echo "Org $ou_name"
  echo ""
  echo "Here is the list of AWS accounts in the OU $ou_id \"$ou_name\""
  echo "-----------------------------------------------------------------------------------"
  echo "| Account Name                                   | Account ID      | OU Name|OU ID|"
  echo "|------------------------------------------------|-----------------|--------|-----|"

  # --- Process each account ---
  while read -r account_line; do
    account_id=$(echo "$account_line" | awk '{print $1}')
    account_name=$(echo "$account_line" | awk '{print $2}')

    # Print to console in table format
    printf "| %-46s | %-15s | %-15s | %-15s |\n" "$account_name" "$account_id" "$ou_name" "$ou_id"

    # Append to CSV
    echo "\"$account_name\",\"$account_id\",\"$ou_name\",\"$ou_id\"" >> "$csv_file"

    # Append to Markdown
    echo "| $account_name | $account_id | $ou_name | $ou_id |" >> "$md_file"
  done <<< "$accounts"

  echo "----------------------------------------------------------------------------------------------------"
  echo "" >> "$md_file"
done < "$input_file"

echo "Done! CSV saved to $csv_file, Markdown saved to $md_file"
