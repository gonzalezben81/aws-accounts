#!/bin/bash
input_file="ou_info.conf"
          
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


  # Check if organizational units were retrieved
  if [[ -z "$ou_id" ]]; then
    echo "No organizational units found or command failed."
    exit 1
  fi
  # Write to CSV
  # echo "OU Name,OU ID,Account Name,Account ID" > "$csv_file"
  # #echo "$ou_id" | jq -r '.[] | [.Id, .Name] | @csv' >> "$csv_file"
  # echo "Organizational units have been written to org_units.csv"
  
  # Write the header of the Markdown file
  echo "# <img src='https://upload.wikimedia.org/wikipedia/commons/9/93/Amazon_Web_Services_Logo.svg' width='30' height='30'> AWS Org Unit: Account Information" > $markdown_file
  echo "This document lists all AWS accounts grouped by Organizational Units (OUs) Test:" >> $markdown_file
  echo "" >> $markdown_file
          

  # Retrieve accounts for the current OU
  accounts=$(aws organizations list-accounts-for-parent --parent-id ${ou_id} --query "Accounts[*].{ID:Id,Name:Name}" --output json)
  
  # Check if accounts exist for the OU
  if [[ -n "$accounts" && "$accounts" != "[]" ]]; then
    # Write the OU section header
    echo "## Org Unit Name: $ou_name" >> $markdown_file
    echo "### Org Unit ID: $ou_id" >> $markdown_file
    echo "" >> $markdown_file
    echo "| Account Name       | Account ID      | Org Unit ID |" >> $markdown_file
    echo "|--------------------|-----------------|-------------|" >> $markdown_file
    
    # Parse and write the accounts
    echo "$accounts" | jq -c '.[]' | while read -r account; do
      account_name=$(echo "$account" | jq -r '.Name')
      account_id=$(echo "$account" | jq -r '.ID')

    # Append to CSV
    # echo "$ou_name,$ou_id,$account_name,$account_id" >> "$csv_file"

        
    printf "| %-18s | %-15s | %-15s |\n" "$account_name" "$account_id" "$ou_id" >> $markdown_file
    done
    echo "" >> $markdown_file
  fi
          
# Add a timestamp at the bottom of the Markdown file
echo "*Report generated on $(date)*" >> $markdown_file

done < "$input_file"
