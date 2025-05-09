# app/jobs/import_csv_job.rb
require 'csv'

class ImportCsvJob
  include Sidekiq::Job
  
  def perform(csv_data)
    puts "Starting CSV import with #{csv_data.length} bytes of data"
    
    # Process each row in the CSV data
    CSV.parse(csv_data, headers: true) do |row|
      # Debug info
      puts "Processing row: #{row.inspect}"
      
      # Create a new Mailed record
      mailed = Mailed.new(
        full_name: row['full_name'],
        first_name: row['first_name'],
        last_name: row['last_name'],
        property_address: row['property_address'],
        property_city: row['property_city'],
        property_state: row['property_state'],
        property_zip: row['property_zip'],
        mailing_address: row['mailing_address'],
        mailing_city: row['mailing_city'],
        mailing_state: row['mailing_state'],
        mailing_zip: row['mailing_zip'],
        mail_month: row['mail_month']
      )
      
      # Handle checkval - convert from currency string to decimal
      if row['checkval'].present? && row['checkval'] != 'Call us'
        # Remove dollar signs, commas, and other non-numeric characters
        numeric_value = row['checkval'].to_s.gsub(/[$,]/, '')
        mailed.checkval = numeric_value if numeric_value.present?
      end
      
      # Save the record and log any errors
      if mailed.save
        puts "Successfully saved record #{mailed.id}"
      else
        puts "Error saving record: #{mailed.errors.full_messages.join(', ')}"
      end
    end
    
    puts "CSV import completed"
  end
end