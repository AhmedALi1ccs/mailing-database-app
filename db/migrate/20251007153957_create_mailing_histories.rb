# db/migrate/XXXXXX_create_mailing_histories.rb
class CreateMailingHistories < ActiveRecord::Migration[7.0]
  def change
    create_table :mailing_histories do |t|
      t.bigint :mailed_id, null: false
      t.decimal :checkval, precision: 15, scale: 2
      t.string :mail_month
      t.integer :mail_year
      t.string :lists
      t.timestamps
    end

    # Add foreign key to the correct table name 'mailed' (singular)
    add_foreign_key :mailing_histories, :mailed, column: :mailed_id
    
    # Add index for faster queries (with shorter custom names)
    add_index :mailing_histories, [:mailed_id, :mail_year, :mail_month], name: 'idx_mailing_hist_period'
    add_index :mailing_histories, :mailed_id, name: 'idx_mailing_hist_mailed'
  end
end

# To run this migration:
# rails db:migrate