class CreateMaileds < ActiveRecord::Migration[7.0]
  def change
    create_table :maileds do |t|
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
    
    # Add indexes for better search performance
    add_index :maileds, :mailing_address
    add_index :maileds, :property_address
    add_index :maileds, :mailing_zip
    add_index :maileds, :property_zip
  end
end