class AddOrderPostcardToMember < ActiveRecord::Migration
  def change
    add_column :members, :order_postcard, :integer
    add_column :members, :reference_postcard_code, :string
    
  end
end
