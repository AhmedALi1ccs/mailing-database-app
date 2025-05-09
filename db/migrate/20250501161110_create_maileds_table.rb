class CreateMailedsTable < ActiveRecord::Migration[7.0]
  def change
    create_table :mailed do |t|
      t.string :full_name
      t.string :first_name
      t.string :last_name
      t.string :mailing_address, null: false
      t.string :mailing_city, null: false
      t.string :mailing_state, null: false
      t.string :mailing_zip, null: false
      t.string :property_address, null: false
      t.string :property_city, null: false
      t.string :property_state, null: false
      t.string :property_zip, null: false
      t.boolean :checkval, default: false

      t.timestamps
    end
    
    add_index :mailed, :mailing_address
    add_index :mailed, :property_address
    add_index :mailed, :mailing_zip
    add_index :mailed, :property_zip
    add_index :mailed, :full_name
    add_index :mailed, :last_name
  end
end