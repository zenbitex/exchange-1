class AddReasonRejectToIdDocument < ActiveRecord::Migration
  def change
    add_column :id_documents, :reason_reject, :integer
  end
end
