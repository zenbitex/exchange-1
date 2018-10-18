class AddCurrentTaoArbToArbHistory < ActiveRecord::Migration
  def change
    add_column :arb_histories, :current_tao_arb, :decimal
  end
end
