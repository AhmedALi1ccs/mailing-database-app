#!/usr/bin/env ruby
require 'csv'

# Path to your CSV file
csv_file = 'db/data/DMC April 2025 .csv'
sql_file = File.open('db/data/import_data.sql', 'w')

sql_file.puts "BEGIN;"
counter = 0

begin
  CSV.foreach(csv_file, headers: true) do |row|
    # Map each column exactly matching your CSV headers
    full_name = row['full_name']&.gsub("'", "''")
    first_name = row['first_name']&.gsub("'", "''")
    last_name = row['last_name']&.gsub("'", "''")
    property_address = row['property_address']&.gsub("'", "''")
    property_city = row['property_city']&.gsub("'", "''")
    property_state = row['property_state']&.gsub("'", "''")
    property_zip = row['property_zip']&.gsub("'", "''")
    mailing_address = row['mailing_address']&.gsub("'", "''")
    mailing_city = row['mailing_city']&.gsub("'", "''")
    mailing_state = row['mailing_state']&.gsub("'", "''")
    mailing_zip = row['mailing_zip']
    mail_month = row['mail_month']&.gsub("'", "''")
    
    # Process checkval - handle if it's a currency value
    checkval_raw = row['checkval']
    if checkval_raw.nil? || checkval_raw.empty?
      checkval = 'NULL'
    else
      # Remove dollar signs, commas, and other non-numeric characters
      numeric_value = checkval_raw.to_s.gsub(/[$,]/, '')
      begin
        Float(numeric_value)
        checkval = numeric_value
      rescue ArgumentError
        puts "Warning: Invalid numeric value '#{checkval_raw}' for checkval in row #{counter+1}, setting to NULL"
        checkval = 'NULL'
      end
    end
    
    # Build SQL statement with all fields
    sql = "INSERT INTO mailed (full_name, first_name, last_name, property_address, property_city, property_state, property_zip, mailing_address, mailing_city, mailing_state, mailing_zip, checkval, mail_month, created_at, updated_at) VALUES "
    
    # Replace nil values with empty strings for string fields
    full_name ||= ''
    first_name ||= ''
    last_name ||= ''
    property_address ||= ''
    property_city ||= ''
    property_state ||= ''
    property_zip ||= ''
    mailing_address ||= ''
    mailing_city ||= ''
    mailing_state ||= ''
    mailing_zip = mailing_zip.to_s
    mail_month ||= ''
    
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
    
    # Debug output for the first few rows to verify data
    if counter <= 3
      puts "Sample data for row #{counter}:"
      puts "full_name: #{full_name}"
      puts "property_address: #{property_address}"
      puts "mailing_address: #{mailing_address}"
      puts "checkval: #{checkval}"
      puts "---"
    end
  end
  
  # Write the transaction commit
  sql_file.puts "COMMIT;"
  
  puts "Successfully converted #{counter} records to SQL."
  puts "SQL file saved as 'db/data/import_data.sql'"
  
rescue StandardError => e
  # Write transaction rollback in case of error
  sql_file.puts "ROLLBACK;"
  puts "Error: #{e.message}"
  puts e.backtrace
ensure
  # Close the file
  sql_file.close
end
