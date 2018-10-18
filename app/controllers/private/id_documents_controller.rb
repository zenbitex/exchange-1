module Private
  class IdDocumentsController < BaseController
    def edit
      @id_document = current_user.id_document || current_user.create_id_document
      @country = "JP"
      @country_current = @id_document.country
      redirect_to edit_authentications_email_path(current_user.id)
    end

    def update
      @id_document = current_user.id_document
      @country_current = params[:id_document][:country]
      params[:id_document][:zipcode] = params[:id_document][:zipcode].zen_to_han
      if @id_document.update_attributes id_document_params
        files = file_params
        files.each do |type, value|
          value.each do |attachable_type, file_name|
            Asset.where(:attachable_id => @id_document.id, :type => type, :attachable_type => attachable_type).destroy_all
            Asset.create!(:file => file_name, :attachable_id => @id_document.id, :attachable_type => attachable_type, :type => type)
          end
        end

        if is_empty
          @id_document.errors.add(:is_empty, true)
          render :edit
          return
        end

        @id_document.submit! if @id_document.unverified?
        if !IdDocument.validate_birthdate(params[:id_document]["birth_date(1i)"], params[:id_document]["birth_date(2i)"], params[:id_document]["birth_date(3i)"])
          @id_document.errors.add(:birth_date, I18n.t('id_documents.invalid_birthdate'))
          render :edit
        else
          redirect_to settings_path, notice: t('.notice')
        end
      else
        @id_document.errors.add(:birth_date, I18n.t('id_documents.invalid_birthdate')) if !IdDocument.validate_birthdate(params[:id_document]["birth_date(1i)"], params[:id_document]["birth_date(2i)"], params[:id_document]["birth_date(3i)"])
        render :edit
      end
    end

    def is_empty
      id_document = id_document_params
      id_document.each do |key, value|
        return true if value == ""
      end
      return false
    end

    private

    def file_params
      types = ['Asset::IdDocumentInfor', 'Asset::IdDocumentFile', 'Asset::IdDocumentTrade']
      symbol = [:id_document_infor_attributes, :id_document_file_attributes, :id_document_trade_attributes]
      files = {}
      data = params.require(:id_document)
      for index in (0..2)
        data_file = data[symbol[index]]
        files[types[index]] = data_file if data_file
      end
      files
    end

    def id_document_params
      params.require(:id_document).permit(:company_name, :company_country, :company_zipcode, :company_city, :company_address,
                                          :company_job_content, :company_trade_purpose, :manager_name, :manager_birth_date, :manager_position,
                                          :manager_country, :manager_city, :manager_address, :manager_zipcode,
                                          :manager_foreign, :manager_role, :type_role, :position, :user_type,
                                          :name, :birth_date, :address, :city, :country, :zipcode,
                                          :id_document_type,:id_bill_type, :job_type, :trade_purpose, :foreign)
    end
  end
end
