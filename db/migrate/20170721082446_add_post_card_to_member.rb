class AddPostCardToMember < ActiveRecord::Migration
  def change
    add_column :members, :post_card, :boolean
  end
end
