#!/bin/bash
input_file="ou_info.conf"

# Check if file exists
if [[ ! -f "$input_file" ]]; then
  echo "File not found!"
  exit 1
fi

markdown_file="accounts.md"
csv_file="org_units_accounts.csv"

# Initialize CSV ONCE
echo "OU Name,OU ID,Account Name,Account ID" > "$csv_file"

# Initialize Markdown ONCE
cat <<EOF > "$markdown_file"
# <img src='https://upload.wikimedia.org/wikipedia/commons/9/93/Amazon_Web_Services_Logo.svg' width='30' height='30'> AWS Org Unit: Account Information

This document lists all AWS accounts grouped by Organizational Units (OUs):

EOF

# Read each OU line
while IFS= read -r line; do
    ou_id=$(echo "$line" | cut -d':' -f3)
    ou_name=$(echo "$line" | cut -d':' -f1)

    [[ -z "$ou_id" ]] && continue

    accounts=$(aws organizations list-accounts-for-parent \
               --parent-id "$ou_id" \
               --query "Accounts[*].{ID:Id,Name:Name}" \
               --output json)

    [[ "$accounts" == "[]" ]] && continue

    {
      echo "## Org Unit Name: $ou_name"
      echo "### Org Unit ID: $ou_id"
      echo ""
      echo "| Account Name | Account ID | Org Unit ID |"
      echo "|--------------|------------|-------------|"
    } >> "$markdown_file"

    # IMPORTANT FIX HERE
    while read -r account; do
        account_name=$(echo "$account" | jq -r '.Name')
        account_id=$(echo "$account" | jq -r '.ID')
        echo "$ou_name,$ou_id,$account_name,$account_id" >> "$csv_file"

        printf "| %-12s | %-10s | %-11s |\n" \
            "$account_name" "$account_id" "$ou_id" >> "$markdown_file"
    done < <(echo "$accounts" | jq -c '.[]')

    echo "" >> "$markdown_file"

done < "$input_file"
