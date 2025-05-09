class AddMailMonthToMailed < ActiveRecord::Migration[7.1]
  def change
    add_column :mailed, :mail_month, :string
  end
end