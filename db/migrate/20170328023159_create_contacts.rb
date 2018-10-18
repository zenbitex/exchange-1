class CreateContacts < ActiveRecord::Migration
  def change
    create_table :contacts do |t|
      t.string :from_email
      t.string :name
      t.string :message
      t.string :category
      t.timestamps
    end
  end
end
