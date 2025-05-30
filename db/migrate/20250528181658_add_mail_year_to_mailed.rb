class AddMailYearToMailed < ActiveRecord::Migration[7.0]
  def up
    # Add the mail_year column
    add_column :mailed, :mail_year, :integer
    
    # Set default year for existing records
    execute "UPDATE mailed SET mail_year = 2024 WHERE mail_year IS NULL"
    
    # Make it non-nullable after setting defaults
    change_column_null :mailed, :mail_year, false
    
    # Add index for better query performance
    add_index :mailed, [:mail_month, :mail_year]
  end
  
  def down
    remove_index :mailed, [:mail_month, :mail_year]
    remove_column :mailed, :mail_year
  end
end