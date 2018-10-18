class Asset < ActiveRecord::Base
  belongs_to :attachable, polymorphic: true

  mount_uploader :file, FileUploader

  def image?
    file.content_type.start_with?('image') if file?
  end
end

class Asset::IdDocumentInfor < Asset
end

class Asset::IdDocumentFile < Asset
end

class Asset::IdDocumentTrade < Asset
end
