class AddListsToMailed < ActiveRecord::Migration[7.1]
  def change
    add_column :mailed, :lists, :text
    
    # Add an index for better search performance if needed
    add_index :mailed, :lists, using: :gin, opclass: :gin_trgm_ops if index_name_exists?(:mailed, :lists)
  end
end