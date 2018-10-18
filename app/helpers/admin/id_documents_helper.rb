module Admin::IdDocumentsHelper
  def check_account_exist object
    @id_document_verified = IdDocument.where.not(id: object.id).where(aasm_state: :verified)
    if @id_document_verified.present?
      check_aasm_state @id_document_verified, object
    end
  end

  def check_aasm_state id_document_type, object
    id_document_type.find do |n|
      if (object.name && object.birth_date).present?
        next if n.name.nil?
        if (object.name.gsub('　', ' ').gsub(/\s+/, '').strip == n.name.gsub('　', ' ').gsub(/\s+/, '').strip && object.birth_date == n.birth_date)
          return "重複登録の可能性があります。確認してください。"
        end
      else
        return nil
      end
    end
  end
end
