class CreateFlags < ActiveRecord::Migration
  def change
    create_table :flags do |t|
      t.string :flag_name
      t.integer :value

      t.timestamps
    end
  end
end
