class ChangePostCardInMember < ActiveRecord::Migration
  def change
    change_column :members, :post_card, :integer
  end
end
