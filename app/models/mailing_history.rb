# app/models/mailing_history.rb
class MailingHistory < ApplicationRecord
  belongs_to :mailed

  validates :mail_month, presence: true
  validates :mail_year, presence: true, numericality: { 
    greater_than: 2000, 
    less_than_or_equal_to: -> { Date.current.year + 1 } 
  }
  validates :checkval, numericality: { allow_nil: true }

  VALID_MONTHS = %w[January February March April May June July August September October November December].freeze
  validates :mail_month, inclusion: { in: VALID_MONTHS }

  # Prevent duplicate entries for same property, month, and year
  validates :mail_month, uniqueness: { 
    scope: [:mailed_id, :mail_year],
    message: "already exists for this property and year" 
  }

  # Format checkval as currency
  def formatted_checkval(include_dollar = true)
    return '' if checkval.nil?
    include_dollar ? "$#{checkval}" : checkval.to_s
  end

  # Get formatted mail period
  def mail_period
    "#{mail_month} #{mail_year}"
  end

  # Calculate date value for sorting
  def mail_date_value
    month_index = VALID_MONTHS.index(mail_month) || 0
    (mail_year * 12) + month_index
  end

  # Parse lists array
  def lists_array
    return [] if lists.blank?
    lists.split(',').map(&:strip).reject(&:blank?)
  end
end