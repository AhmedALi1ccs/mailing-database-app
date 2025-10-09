# app/models/mailed.rb
class Mailed < ApplicationRecord
  self.table_name = "mailed"
  
  # Add relationship to history
  has_many :mailing_histories, dependent: :destroy
  
  # Validations
  validates :mailing_address, :mailing_city, :mailing_state, :mailing_zip, presence: true
  validates :property_address, :property_city, :property_state, :property_zip, presence: true
  validates :checkval, numericality: { allow_nil: true }
  validates :mail_month, presence: true
  validates :mail_year, presence: true, numericality: { 
    greater_than: 2000, 
    less_than_or_equal_to: -> { Date.current.year + 1 } 
  }

  VALID_MONTHS = %w[January February March April May June July August September October November December].freeze
  validates :mail_month, inclusion: { in: VALID_MONTHS }

  # Callback to save history before update
  before_update :save_to_history, if: :campaign_data_changed?

  # Format checkval as currency - or show "Multiple Campaigns" if history exists
  def formatted_checkval(include_dollar = true)
    if has_multiple_campaigns?
      return 'Multiple Campaigns'
    end
    return '' if checkval.nil?
    include_dollar ? "$#{checkval}" : checkval.to_s
  end

  # Get formatted mail period - or show "Multiple Campaigns" if history exists
  def mail_period
    if has_multiple_campaigns?
      return 'Multiple Campaigns'
    end
    "#{mail_month} #{mail_year}"
  end

  # Check if this property has multiple campaigns
  def has_multiple_campaigns?
    mailing_histories.exists?
  end

  # Get display value for checkval (used in search results)
  def display_checkval
    has_multiple_campaigns? ? 'Multiple Campaigns' : formatted_checkval
  end

  # Get display value for mail period (used in search results)
  def display_mail_period
    has_multiple_campaigns? ? 'Multiple Campaigns' : mail_period
  end

  # Calculate date value for comparison
  def mail_date_value
    month_index = VALID_MONTHS.index(mail_month) || 0
    (mail_year * 12) + month_index
  end

  def lists_array
    return [] if lists.blank?
    lists.split(',').map(&:strip).reject(&:blank?)
  end

  def add_to_list(list_name)
    return if list_name.blank?
    
    current_lists = lists_array
    unless current_lists.include?(list_name.strip)
      current_lists << list_name.strip
      self.lists = current_lists.join(', ')
    end
  end

  def remove_from_list(list_name)
    return if list_name.blank?
    
    current_lists = lists_array
    current_lists.delete(list_name.strip)
    self.lists = current_lists.join(', ')
  end

  def in_list?(list_name)
    return false if list_name.blank?
    lists_array.include?(list_name.strip)
  end

  # Get all campaign history sorted by date (newest first)
  def campaign_history
    mailing_histories.order(mail_year: :desc, mail_month: :desc)
  end

  # Get complete history including current record
  # FIXED: Always show actual month/year, never "Multiple Campaigns" in full_history
  def full_history
    history = campaign_history.map do |h|
      {
        mail_period: "#{h.mail_month} #{h.mail_year}",
        checkval: h.checkval,
        formatted_checkval: h.formatted_checkval,
        lists: h.lists_array,
        mail_month: h.mail_month,
        mail_year: h.mail_year,
        created_at: h.created_at
      }
    end

    # Add current record as the latest - always show actual period
    current = {
      mail_period: "#{mail_month} #{mail_year}",
      checkval: checkval,
      formatted_checkval: checkval ? "$#{checkval}" : '',
      lists: lists_array,
      mail_month: mail_month,
      mail_year: mail_year,
      created_at: updated_at,
      current: true
    }

    [current] + history
  end

  # Search method
  def self.search(query)
    if query.present?
      where("full_name ILIKE :query OR
             first_name ILIKE :query OR
             last_name ILIKE :query OR
             mailing_address ILIKE :query OR 
             mailing_city ILIKE :query OR 
             mailing_state ILIKE :query OR 
             mailing_zip ILIKE :query OR 
             property_address ILIKE :query OR 
             property_city ILIKE :query OR 
             property_state ILIKE :query OR 
             property_zip ILIKE :query OR
             lists ILIKE :query", query: "%#{query}%")
    else
      all
    end
  end

  private

  # Check if campaign-related data has changed
  def campaign_data_changed?
    checkval_changed? || mail_month_changed? || mail_year_changed? || lists_changed?
  end

  # Save current data to history before updating
  def save_to_history
    # Only save if the old values exist and it's a different period
    if (checkval_was.present? || mail_month_was.present? || mail_year_was.present?)
      # Don't save if this exact period already exists in history
      existing_history = mailing_histories.find_by(
        mail_month: mail_month_was,
        mail_year: mail_year_was
      )
      
      unless existing_history
        mailing_histories.create(
          checkval: checkval_was,
          mail_month: mail_month_was,
          mail_year: mail_year_was,
          lists: lists_was
        )
      end
    end
  end
end