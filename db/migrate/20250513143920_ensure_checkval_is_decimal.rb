class EnsureCheckvalIsDecimal < ActiveRecord::Migration[7.1]
  def up
    # First try to check the column type
    begin
      # If the column is boolean, replace it
      if column_exists?(:mailed, :checkval)
        # Get the column type using raw SQL to avoid loading models
        column_type = connection.select_value("SELECT data_type FROM information_schema.columns WHERE table_name = 'mailed' AND column_name = 'checkval'")
        
        if column_type == 'boolean'
          # Remove the boolean column
          remove_column :mailed, :checkval
          
          # Add a new decimal column
          add_column :mailed, :checkval, :decimal, precision: 15, scale: 2
        elsif column_type != 'numeric' && column_type != 'decimal'
          # Change to decimal if not already decimal/numeric
          change_column :mailed, :checkval, :decimal, precision: 15, scale: 2
        end
      end
    rescue => e
      # Log the error and use a more direct approach
      puts "Error checking column type: #{e.message}"
      
      # Directly execute SQL for more reliable behavior
      execute <<-SQL
        ALTER TABLE mailed 
        ALTER COLUMN checkval TYPE decimal(15,2) 
        USING CASE 
          WHEN checkval IS TRUE THEN 1.0 
          WHEN checkval IS FALSE THEN 0.0 
          ELSE NULL 
        END;
      SQL
    end
  end

  def down
    # No rollback necessary
  end
end