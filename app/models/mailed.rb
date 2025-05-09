class Mailed < ApplicationRecord
  self.table_name = "mailed"
  
  # Validations
  validates :mailing_address, :mailing_city, :mailing_state, :mailing_zip, presence: true
  validates :property_address, :property_city, :property_state, :property_zip, presence: true
  # Format checkval as currency
def formatted_checkval
  checkval.present? ? "$#{sprintf('%.2f', checkval)}" : nil
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
             property_zip ILIKE :query", query: "%#{query}%")
    else
      all
    end
  end
end