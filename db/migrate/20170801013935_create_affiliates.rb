class CreateAffiliates < ActiveRecord::Migration
  def change
    create_table :affiliates do |t|
      t.integer :member_id
      t.decimal :bonus, precision: 32, scale: 0
      t.integer :people
      
      t.timestamps
    end
  end
end
