#!/usr/bin/env ruby

require 'csv'

# This script converts a CSV file to SQL INSERT statements
# with special handling for currency values

# Path to your CSV file - update this path
csv_file = 'db/data/DMC April 2025 .csv'

# Output SQL file
sql_file = File.open('db/data/import_data.sql', 'w')

# Write the transaction beginning
sql_file.puts "BEGIN;"

# Counter for progress tracking
counter = 0

begin
  # Process the CSV file
  CSV.foreach(csv_file, headers: true) do |row|
    # Escape single quotes in string values
    full_name = row['full name']&.gsub("'", "''")
    first_name = row['First Name']&.gsub("'", "''")
    last_name = row['Last Name']&.gsub("'", "''")
    property_address = row['Property address']&.gsub("'", "''")
    property_city = row['Property city']&.gsub("'", "''")
    property_state = row['Property state']&.gsub("'", "''")
    property_zip = row['Property zip']&.gsub("'", "''")
    mailing_address = row['Mailing address']&.gsub("'", "''")
    mailing_city = row['Mailing city']&.gsub("'", "''")
    mailing_state = row['Mailing state']&.gsub("'", "''")
    mailing_zip = row['Mailing zip']
    mail_month = row['mail_month']&.gsub("'", "''")
    
    # Process checkval as currency
    checkval_raw = row['checkval']
    if checkval_raw.nil? || checkval_raw.empty?
      checkval = 'NULL'
    else
      # Remove dollar signs, commas, and other non-numeric characters, preserving the decimal point
      numeric_value = checkval_raw.gsub(/[$,]/, '')
      # Check if it's a valid number
      begin
        Float(numeric_value)
        checkval = numeric_value
      rescue ArgumentError
        puts "Warning: Invalid numeric value '#{checkval_raw}' for checkval in row #{counter+1}, setting to NULL"
        checkval = 'NULL'
      end
    end
    
    # Build the SQL INSERT statement
    sql = "INSERT INTO mailed (full_name, first_name, last_name, property_address, property_city, property_state, property_zip, mailing_address, mailing_city, mailing_state, mailing_zip, checkval, mail_month, created_at, updated_at) VALUES "
    
    # Create the values section, handling NULL for checkval correctly
    if checkval == 'NULL'
      sql += "('#{full_name}', '#{first_name}', '#{last_name}', '#{property_address}', '#{property_city}', '#{property_state}', '#{property_zip}', '#{mailing_address}', '#{mailing_city}', '#{mailing_state}', '#{mailing_zip}', #{checkval}, '#{mail_month}', NOW(), NOW());"
    else
      sql += "('#{full_name}', '#{first_name}', '#{last_name}', '#{property_address}', '#{property_city}', '#{property_state}', '#{property_zip}', '#{mailing_address}', '#{mailing_city}', '#{mailing_state}', '#{mailing_zip}', #{checkval}, '#{mail_month}', NOW(), NOW());"
    end
    
    # Write the SQL statement to the file
    sql_file.puts sql
    
    # Increment and show progress
    counter += 1
    puts "Processed #{counter} records" if (counter % 1000) == 0
  end
  
  # Write the transaction commit
  sql_file.puts "COMMIT;"
  
  puts "Successfully converted #{counter} records to SQL."
  puts "SQL file saved as 'db/data/import_data.sql'"
  
rescue StandardError => e
  # Write transaction rollback in case of error
  sql_file.puts "ROLLBACK;"
  puts "Error: #{e.message}"
ensure
  # Close the file
  sql_file.close
end
