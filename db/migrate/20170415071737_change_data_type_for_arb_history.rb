class ChangeDataTypeForArbHistory < ActiveRecord::Migration
  def change
  	change_column :arb_histories, :tao_amount, :decimal, :precision => 32, :scale => 0
    change_column :arb_histories, :current_tao_arb, :decimal, :precision => 32, :scale => 0
  end
end
