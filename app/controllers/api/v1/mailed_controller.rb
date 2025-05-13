# app/controllers/api/v1/mailed_controller.rb
require 'csv'

module Api
  module V1
    class MailedController < ApplicationController
      # Skip CSRF protection for API endpoints
      skip_before_action :verify_authenticity_token, if: :json_request?
      before_action :set_mailed, only: [:show, :update, :destroy]

      # GET /api/v1/mailed
      def index
        @maileds = Mailed.all
        render json: @maileds
      end

      # GET /api/v1/mailed/1
      def show
        render json: @mailed
      end

      # POST /api/v1/mailed
      def create
        @mailed = Mailed.new(mailed_params)

        if @mailed.save
          render json: @mailed, status: :created
        else
          render json: @mailed.errors, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/mailed/1
      def update
        if @mailed.update(mailed_params)
          render json: @mailed
        else
          render json: @mailed.errors, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/mailed/1
      def destroy
        @mailed.destroy
        head :no_content
      end

      # GET /api/v1/search
      def search
        query = params[:q]
        search_type = params[:type] # This will be 'mailing', 'property', or nil (for both)
        
        if query.present?
          case search_type
          when 'mailing'
            # Search only mailing addresses
            exact_matches = Mailed.where("mailing_address = ?", query)
            @results = exact_matches.exists? ? exact_matches : Mailed.where("mailing_address ILIKE ?", "%#{query}%")
          when 'property'
            # Search only property addresses
            exact_matches = Mailed.where("property_address = ?", query)
            @results = exact_matches.exists? ? exact_matches : Mailed.where("property_address ILIKE ?", "%#{query}%")
          else
            # Search both (default behavior)
            exact_matches = Mailed.where("mailing_address = ? OR property_address = ?", query, query)
            
            if exact_matches.exists?
              @results = exact_matches
            else
              @results = Mailed.search(query)
            end
          end
        else
          @results = []
        end
        
        render json: @results.as_json(except: [:created_at, :updated_at])
      end

      # GET /api/v1/mailed/export
      def export
        # Get all records or filter if needed
        @records = Mailed.all
        
        # Determine export format
        format = params[:format] || 'csv'
        
        case format.downcase
        when 'csv'
          export_csv
        when 'xlsx'
          export_xlsx
        when 'json'
          export_json
        else
          render json: { error: "Unsupported format: #{format}" }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/mailed/import
      def import
        if params[:file].nil?
          render json: { error: "No file uploaded" }, status: :bad_request
          return
        end

        begin
          # Read the file content
          csv_content = params[:file].read
          imported_count = 0
          updated_count = 0
          failed_count = 0
          errors = []
          
          # Process the CSV directly
          CSV.parse(csv_content, headers: true) do |row|
            # Check if a record with this property address already exists
            existing_record = Mailed.find_by(property_address: row['property_address'])
            
            if existing_record
              # If record exists, compare mail_month and update if new one is more recent
              if should_update_record?(existing_record.mail_month, row['mail_month'])
                # Update existing record
                existing_record.assign_attributes(
                  full_name: row['full_name'],
                  first_name: row['first_name'],
                  last_name: row['last_name'],
                  mailing_address: row['mailing_address'],
                  mailing_city: row['mailing_city'],
                  mailing_state: row['mailing_state'],
                  mailing_zip: row['mailing_zip'],
                  property_city: row['property_city'],
                  property_state: row['property_state'],
                  property_zip: row['property_zip'],
                  mail_month: row['mail_month']
                )
                
                # Handle checkval
                if row['checkval'].present? && row['checkval'] != 'Call us'
                  numeric_value = row['checkval'].to_s.gsub(/[$,]/, '')
                  existing_record.checkval = numeric_value if numeric_value.present?
                end
                
                if existing_record.save
                  updated_count += 1
                else
                  failed_count += 1
                  errors << "Row update failed: #{existing_record.errors.full_messages.join(', ')}"
                end
              end
            else
              # Create a new record if no duplicate exists
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
              
              # Handle checkval
              if row['checkval'].present?
                value_string = row['checkval'].to_s.strip

                if value_string.downcase == 'call us' || value_string.downcase == 'n/a'
                  mailed.checkval = nil
                else
                  # Handle both with and without dollar sign
                  # Remove dollar signs, commas, spaces, and other non-numeric characters
                  numeric_string = value_string.gsub(/[$,\s]/, '')
                  
                  # Check if it's a valid numeric string
                  if numeric_string.match?(/\A-?\d+(\.\d+)?\z/)
                    # Convert to BigDecimal for precision
                    mailed.checkval = BigDecimal(numeric_string)
                  else
                    # Log invalid format but continue with import
                    Rails.logger.warn("Invalid checkval format: '#{value_string}' for row with property: #{row['property_address']}")
                    mailed.checkval = nil
                  end
                end
              end

              # Save the new record
              if mailed.save
                imported_count += 1
              else
                failed_count += 1
                errors << "Row import failed: #{mailed.errors.full_messages.join(', ')}"
              end
            end
          end # This closes the CSV.parse block
          
          # Return success response with details - OUTSIDE the CSV.parse block but INSIDE the begin block
          render json: {
            success: true,
            message: "Import completed: #{imported_count} new records, #{updated_count} updated, #{failed_count} failed.",
            imported: imported_count,
            updated: updated_count,
            failed: failed_count,
            errors: errors.take(10) # Show first 10 errors if any
          }, status: :ok
          
        rescue StandardError => e
          # Return error response
          render json: {
            success: false,
            error: e.message
          }, status: :unprocessable_entity
        end
      end

      private
        # Private helper methods for export
        def export_csv
          # Get format preference from params
          include_dollar = params[:include_dollar] != 'false'
          
          csv_data = CSV.generate(headers: true) do |csv|
            # Add headers
            csv << ['full_name', 'first_name', 'last_name', 'property_address', 'property_city', 
                    'property_state', 'property_zip', 'mailing_address', 'mailing_city', 
                    'mailing_state', 'mailing_zip', 'checkval', 'mail_month']
            
            # Add rows
            @records.each do |record|
              csv << [
                record.full_name,
                record.first_name, 
                record.last_name,
                record.property_address,
                record.property_city,
                record.property_state,
                record.property_zip,
                record.mailing_address,
                record.mailing_city,
                record.mailing_state,
                record.mailing_zip,
                # Format checkval according to preference
                record.formatted_checkval(include_dollar),
                record.mail_month
              ]
            end
          end
          
          # Send the file
          send_data csv_data, 
                    type: 'text/csv', 
                    disposition: 'attachment', 
                    filename: "mailing-data-#{Date.today}.csv"
        end

        def export_xlsx
          # For Excel export, you'll need a gem like 'caxlsx'
          require 'axlsx'
          
          package = Axlsx::Package.new
          workbook = package.workbook
          
          # Add worksheet
          workbook.add_worksheet(name: "Mailing Data") do |sheet|
            # Add headers
            sheet.add_row ['full_name', 'first_name', 'last_name', 'property_address', 'property_city', 
                          'property_state', 'property_zip', 'mailing_address', 'mailing_city', 
                          'mailing_state', 'mailing_zip', 'checkval', 'mail_month']
            
            # Add data rows
            @records.each do |record|
              sheet.add_row [
                record.full_name,
                record.first_name, 
                record.last_name,
                record.property_address,
                record.property_city,
                record.property_state,
                record.property_zip,
                record.mailing_address,
                record.mailing_city,
                record.mailing_state,
                record.mailing_zip,
                record.checkval,
                record.mail_month
              ]
            end
          end
          
          # Generate the file
          file_contents = package.to_stream.read
          
          # Send the file
          send_data file_contents, 
                    type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 
                    disposition: 'attachment', 
                    filename: "mailing-data-#{Date.today}.xlsx"
        end

        def export_json
          render json: @records
        end

        # Check if the request is JSON
        def json_request?
          request.format.json?
        end

        # Helper method for determining if a record should be updated based on month
        def should_update_record?(existing_month, new_month)
          # Define month order for comparison
          months = ["January", "February", "March", "April", "May", "June", 
                    "July", "August", "September", "October", "November", "December"]
          
          # If either month is nil or doesn't match our known months, use string comparison
          return new_month > existing_month if !months.include?(existing_month) || !months.include?(new_month)
          
          # Compare by month order (higher index = more recent)
          months.index(new_month) >= months.index(existing_month)
        end
      
        # Use callbacks to share common setup or constraints between actions
        def set_mailed
          @mailed = Mailed.find(params[:id])
        end

        # Only allow a list of trusted parameters through
        def mailed_params
          params.require(:mailed).permit(
            :full_name,
            :first_name,
            :last_name,
            :mailing_address,
            :mailing_city,
            :mailing_state,
            :mailing_zip,
            :property_address,
            :property_city,
            :property_state,
            :property_zip,
            :checkval,
            :mail_month
          )
        end
    end
  end
end