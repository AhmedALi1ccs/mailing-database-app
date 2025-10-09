# app/controllers/api/v1/mailed_controller.rb
require 'csv'

module Api
  module V1
    class MailedController < ApplicationController
      skip_before_action :verify_authenticity_token, if: :json_request?
      before_action :set_mailed, only: [:show, :update, :destroy]

      # GET /api/v1/mailed
      def index
        @maileds = Mailed.all
        render json: @maileds
      end

      # GET /api/v1/mailed/1
      def show
        # Include history in the response
        render json: @mailed.as_json(
          methods: :full_history,
          except: [:created_at, :updated_at]
        )
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
        search_type = params[:type]
        
        if query.present?
          case search_type
          when 'mailing'
            exact_matches = Mailed.where("mailing_address = ?", query)
            @results = exact_matches.exists? ? exact_matches : Mailed.where("mailing_address ILIKE ?", "%#{query}%")
          when 'property'
            exact_matches = Mailed.where("property_address = ?", query)
            @results = exact_matches.exists? ? exact_matches : Mailed.where("property_address ILIKE ?", "%#{query}%")
          else
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
        
        # Add display fields for multiple campaigns
        results_with_display = @results.map do |record|
          record.as_json(except: [:created_at, :updated_at]).merge(
            display_checkval: record.display_checkval,
            display_mail_period: record.display_mail_period,
            has_multiple_campaigns: record.has_multiple_campaigns?
          )
        end
        
        render json: results_with_display
      end

      # GET /api/v1/mailed/export
      def export
        @records = Mailed.all
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
          start_time = Time.now
          
          processed = 0
          imported = 0
          updated = 0
          failed = 0
          
          csv = CSV.parse(params[:file].read, headers: true)
          
          csv.each do |row|
            processed += 1
            
            if processed % 1000 == 0
              Rails.logger.info("Processing row #{processed} of #{csv.count}")
            end
            
            begin
              if row['property_address'].blank?
                failed += 1
                next
              end
              
              # Find existing record by property address
              existing = Mailed.find_by(property_address: row['property_address'])
              
              if existing
                # Check if this is a newer campaign
                if should_update_record?(existing, row)
                  # The before_update callback will automatically save to history
                  existing.assign_attributes(
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
                    checkval: row['checkval'],
                    mail_month: row['mail_month'],
                    mail_year: parse_mail_year(row['mail_year']),
                    lists: row['lists']
                  )
                  
                  if existing.save
                    updated += 1
                  else
                    failed += 1
                    Rails.logger.error("Failed to update: #{existing.errors.full_messages}")
                  end
                else
                  # Even if not updating current, add to history if it's a different period
                  add_to_history_if_unique(existing, row)
                end
              else
                # Create new record
                new_record = Mailed.new(
                  full_name: row['full_name'],
                  first_name: row['first_name'],
                  last_name: row['last_name'],
                  mailing_address: row['mailing_address'],
                  mailing_city: row['mailing_city'],
                  mailing_state: row['mailing_state'],
                  mailing_zip: row['mailing_zip'],
                  property_address: row['property_address'],
                  property_city: row['property_city'],
                  property_state: row['property_state'],
                  property_zip: row['property_zip'],
                  checkval: row['checkval'],
                  mail_month: row['mail_month'],
                  mail_year: parse_mail_year(row['mail_year']),
                  lists: row['lists']
                )
                
                if new_record.save
                  imported += 1
                else
                  failed += 1
                  Rails.logger.error("Failed to create: #{new_record.errors.full_messages}")
                end
              end
            rescue => e
              Rails.logger.error("Error processing row #{processed}: #{e.message}")
              failed += 1
            end
          end
          
          duration = Time.now - start_time
          
          render json: {
            success: true,
            message: "Import completed successfully",
            total: processed,
            imported: imported,
            updated: updated,
            failed: failed,
            duration: duration.round(2)
          }, status: :ok
          
        rescue => e
          Rails.logger.error("Import failed: #{e.message}")
          
          render json: {
            success: false,
            error: e.message
          }, status: :unprocessable_entity
        end
      end

      private

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
                                        'mailing_state', 'mailing_zip', 'checkval', 'mail_month', 'mail_year', 'lists'])

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
              record.mail_month,
              record.mail_year,
              record.lists
            ])
          end
        end
      end

      def export_xlsx
        require 'axlsx'
        
        package = Axlsx::Package.new
        workbook = package.workbook
        
        workbook.add_worksheet(name: "Mailing Data") do |sheet|
          sheet.add_row ['full_name', 'first_name', 'last_name', 'property_address', 'property_city', 
                        'property_state', 'property_zip', 'mailing_address', 'mailing_city', 
                        'mailing_state', 'mailing_zip', 'checkval', 'mail_month', 'mail_year', 'lists']
          
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
              record.mail_month,
              record.mail_year,
              record.lists
            ]
          end
        end
        
        file_contents = package.to_stream.read
        
        send_data file_contents, 
                  type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 
                  disposition: 'attachment', 
                  filename: "mailing-data-#{Date.today}.xlsx"
      end

      def export_json
        render json: @records
      end

      def json_request?
        request.format.json?
      end

      def parse_mail_year(year_value)
        return Date.current.year if year_value.blank?
        
        year = year_value.to_i
        if year >= 2000 && year <= Date.current.year + 5
          year
        else
          Date.current.year
        end
      end

      def should_update_record?(existing_record, new_row)
        new_year = parse_mail_year(new_row['mail_year'])
        new_month = new_row['mail_month']
        
        return true if new_month.blank?
        
        existing_value = existing_record.mail_date_value
        
        months = Mailed::VALID_MONTHS
        new_month_index = months.index(new_month) || 0
        new_value = (new_year * 12) + new_month_index
        
        # Update if new record is newer
        new_value >= existing_value
      end

      # Add campaign to history if it's not already there
      def add_to_history_if_unique(existing_record, new_row)
        new_year = parse_mail_year(new_row['mail_year'])
        new_month = new_row['mail_month']
        
        # Check if this period already exists in history
        history_exists = existing_record.mailing_histories.exists?(
          mail_month: new_month,
          mail_year: new_year
        )
        
        # Check if it matches current record
        is_current = (existing_record.mail_month == new_month && 
                     existing_record.mail_year == new_year)
        
        # Add to history if unique
        unless history_exists || is_current
          existing_record.mailing_histories.create(
            checkval: new_row['checkval'],
            mail_month: new_month,
            mail_year: new_year,
            lists: new_row['lists']
          )
        end
      end

      def set_mailed
        @mailed = Mailed.find(params[:id])
      end

      def mailed_params
        params.require(:mailed).permit(
          :full_name, :first_name, :last_name,
          :mailing_address, :mailing_city, :mailing_state, :mailing_zip,
          :property_address, :property_city, :property_state, :property_zip,
          :checkval, :mail_month, :mail_year, :lists
        )
      end
    end
  end
end