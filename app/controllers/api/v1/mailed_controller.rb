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
    # Initialize counters and tracking
    start_time = Time.now
    processed = 0
    imported = 0
    updated = 0
    failed = 0
    error_samples = []
    
    # Read file
    file_content = params[:file].read
    
    # Get total rows (for progress tracking)
    total_rows = CSV.parse(file_content, headers: true).count
    Rails.logger.info("CSV contains #{total_rows} rows")
    
    # Reset file position
    params[:file].rewind
    
    # Process CSV with detailed tracking
    CSV.parse(params[:file].read, headers: true).each do |row|
      processed += 1
      
      # Log progress every 1000 rows
      if processed % 1000 == 0
        elapsed = Time.now - start_time
        rate = processed / elapsed
        est_remaining = (total_rows - processed) / rate
        
        Rails.logger.info("Import progress: #{processed}/#{total_rows} rows (#{(processed.to_f/total_rows*100).round(1)}%), " + 
                         "Rate: #{rate.round(1)} rows/sec, " + 
                         "Est. remaining: #{est_remaining.round(1)}s, " + 
                         "Imported: #{imported}, Updated: #{updated}, Failed: #{failed}")
      end
      
      # Continue with your existing row processing logic
      begin
        # Existing row processing code
        # ...
        
        # Update counters based on result
        if result == :imported
          imported += 1
        elsif result == :updated
          updated += 1
        else
          failed += 1
          # Collect sample errors (limit to 10)
          if error_samples.size < 10
            error_samples << { row: processed, error: error_message, sample: row.to_h.slice(*row.headers.first(3)) }
          end
        end
      rescue => e
        failed += 1
        if error_samples.size < 10
          error_samples << { row: processed, error: e.message, sample: row.to_h.slice(*row.headers.first(3)) }
        end
      end
    end
    
    # Calculate stats
    duration = Time.now - start_time
    success_rate = ((imported + updated).to_f / processed * 100).round(2)
    
    # Log detailed completion
    Rails.logger.info("Import completed: #{processed} rows processed in #{duration.round(2)}s")
    Rails.logger.info("Results: #{imported} imported, #{updated} updated, #{failed} failed (#{success_rate}% success rate)")
    
    if failed > 0
      Rails.logger.info("Sample errors: #{error_samples.inspect}")
    end
    
    # Return detailed report
    render json: {
      success: true,
      message: "Import completed with #{success_rate}% success rate",
      stats: {
        file_name: params[:file].original_filename,
        total_rows: total_rows,
        processed: processed,
        imported: imported,
        updated: updated,
        failed: failed,
        duration: duration.round(2),
        rows_per_second: (processed / duration).round(2)
      },
      error_samples: error_samples
    }, status: :ok
    
  rescue => e
    Rails.logger.error("Import failed: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    
    render json: {
      success: false,
      error: e.message,
      stats: {
        processed: processed,
        imported: imported,
        updated: updated,
        failed: failed
      }
    }, status: :unprocessable_entity
  end
end

      private
        # Private helper methods for export
        def export_csv
  include_dollar = params[:include_dollar] != 'false'

  headers['Content-Type'] = 'text/csv'
  headers['Content-Disposition'] = "attachment; filename=\"mailing-data-#{Date.today}.csv\""
  headers['Last-Modified'] = Time.now.ctime.to_s
  headers['Cache-Control'] = 'no-cache'
  headers.delete('Content-Length')

  self.response_body = Enumerator.new do |yielder|
    yielder << CSV.generate_line(['full_name', 'first_name', 'last_name', 'property_address', 'property_city', 
                                  'property_state', 'property_zip', 'mailing_address', 'mailing_city', 
                                  'mailing_state', 'mailing_zip', 'checkval', 'mail_month'])

    Mailed.find_each(batch_size: 1000) do |record|
      yielder << CSV.generate_line([
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
        record.formatted_checkval(include_dollar),
        record.mail_month
      ])
    end
  end
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