class CreateMemberSettings < ActiveRecord::Migration
  def change
    create_table :member_settings do |t|
      t.references :member, index: true, foreign_key: true
      t.text :send_email
      t.text :two_factor

      t.timestamps
    end
  end
end
