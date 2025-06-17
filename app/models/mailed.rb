class Mailed < ApplicationRecord
  self.table_name = "mailed"
  
  # Validations
  validates :mailing_address, :mailing_city, :mailing_state, :mailing_zip, presence: true
  validates :property_address, :property_city, :property_state, :property_zip, presence: true
  validates :checkval, numericality: { allow_nil: true }
  validates :mail_month, presence: true
  validates :mail_year, presence: true, numericality: { 
    greater_than: 2000, 
    less_than_or_equal_to: -> { Date.current.year + 1 } 
  }

  # Valid months for validation
  VALID_MONTHS = %w[January February March April May June July August September October November December].freeze
  validates :mail_month, inclusion: { in: VALID_MONTHS }

  # Format checkval as currency
  def formatted_checkval(include_dollar = true)
    return '' if checkval.nil?
    include_dollar ? "$#{checkval}" : checkval.to_s
  end

  # New method to get formatted mail period
  def mail_period
    "#{mail_month} #{mail_year}"
  end

  # New method to compare mail periods
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

  # Search method (unchanged)
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
end