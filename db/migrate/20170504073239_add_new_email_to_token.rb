class AddNewEmailToToken < ActiveRecord::Migration
  def change
    add_column :tokens, :new_email, :string
  end
end
