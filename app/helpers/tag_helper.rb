module TagHelper
  def member_tag(key)
    raise unless MemberTag.find_by_key(key)
    content_tag('span', I18n.t("tags.#{key}"), :class => "member-tag #{key}")
  end

  def admin_asset_tag(asset, id)
    return if asset.blank?
    img = Asset.where(:id => id)
    img1 = img.where(:attachable_id => img[0]['attachable_id'])

    if asset.image?
      a = img1.first.file.url
      return link_to image_tag(a, style: 'max-width:500px;max-height:500px;'), a, target: '_blank'
    else
      return link_to asset['file'], asset.file.url
    end

  end

  
  def img_asset_tag(asset, id)
    return if asset.blank?
    img = Asset.where(:id => id)
    img1 = img.where(:attachable_id => img[0]['attachable_id'])
    return image_tag(img1.first.file.url, class: "user-image", style: "display: none")
  end

  def id_document_link_to(asset)
    return if asset.blank?
    if asset.image?
      a = asset.file.url
      return link_to image_tag(a, style: 'max-width:500px;max-height:500px;'), a, target: '_blank'
    else
      return link_to asset['file'], asset.file.url
    end
  end

  def id_document_image(asset)
    return if asset.blank?
    return image_tag(asset.file.url, class: "id_document_image_load #{asset.type.gsub 'Asset::', ''} #{asset.attachable_type}")
  end

  def member_id_to_id_document_id(member_id)
    mem = Member.includes(:id_document).find(member_id)
    if mem.nil?
      return 0   
    end
    return mem.id_document.id
  end

  def bank_code_to_name(code)
    bankName = I18n.t("banks.#{code}", default: code)
    if code == ""
      banks = "" 
      bankName.each do |index, value|
        banks = banks + value + "<br/>"
      end
      return banks.html_safe
    else 
      bankName
    end
  end
end
