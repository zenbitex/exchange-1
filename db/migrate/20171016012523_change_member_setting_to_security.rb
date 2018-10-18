class ChangeMemberSettingToSecurity < ActiveRecord::Migration
  def change
    rename_table :member_settings, :securities
  end
end
