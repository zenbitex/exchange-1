require 'csv'
class Postcard
  attr_reader :error
  def initialize
    init_nexway
  end
  
  def send_post_card user_id
    begin
      @user = IdDocument.find_by(member_id: user_id)
      if @user.zipcode.nil? || @user.city.nil? || @user.address.nil? || @user.name.nil? || @user.created_at.nil?
        @error = "ユーザの情報が違う"
        return false
      end

      create_csv @user.zipcode, @user.city, @user.address
      order_id = send_order
      is_success = false
      if !order_id
        @error = "ユーザーのハガキを送信できません(#{@error})"
      elsif @user.member.update_attributes(post_card: 1, order_postcard: order_id)
        PostcardMailer.postcard_mailer(@user.member, 0).deliver
        is_success = true
      end
      # send post card of company
      if @user.user_type == 1
        if @user.company_zipcode.nil? || @user.company_city.nil? || @user.company_address.nil?
          @error = "会社の情報が違う"
          return false
        end

        create_csv @user.company_zipcode, @user.company_city, @user.company_address
        order_id = send_order
        if !order_id
          @error = "会社のハガキを送信できません(#{@error})"
        elsif @user.member.update_attributes(post_card: 1, order_postcard_company: order_id)
          return is_success
        end
      end
      return is_success
    rescue Exception => e
      @error = e
      return false
    end
    
  end

  def send_order
    return false if get_id_registration == false
    @id_pdf_file = upload_file @pdf_file, "postcard.pdf"
    return false if @id_pdf_file.nil?
    return false if register_card(@id_pdf_file) == false
    @id_csv_file = upload_file @csv_file, "postcard.csv"
    return false if @id_csv_file.nil?
    return false if receiver_register(@id_csv_file).nil?
    order_id = order
  end

  def create_csv zipcode, city, address
    time =  @user.created_at
    CSV.open(@csv_file,'w') do |test|
      test << ["外部コード", "郵便番号", "住所①", "名称①", "名称②"]
      test << [@user.member_id, zipcode, city + address, "#{@user.name} 様", "登録時間: " + time.strftime('%F') + "-" + time.strftime('%X')]
    end
  end

  def init_nexway
    if Rails.env.production?
      wsdl = "https://onbin.jp/e-ondemandapi/api.asmx?WSDL"
    else 
      wsdl = "https://onbin.jp/e-ondemandapi-demo/api.asmx?WSDL"
    end
    header = {
      "e:ApiCredential" => {
        "e:e_onUser" => ENV['NEXWAY_USER'],
        "e:e_onPassword"=> ENV['NEXWAY_PASSWORD']
      }
    }
    @client = Savon.client( 
      wsdl: wsdl,
      ssl_verify_mode: :none, 
      soap_header: header,
      ssl_version: :TLSv1,
      namespaces: { 
                    "xmlns:e"=>"https://onbin.jp/e-ondemandApi/",
                    "xmlns:soap"=>"http://www.w3.org/2003/05/soap-envelope",
                  },
    )
    # su dung dich vu gui postcard co design kieu 簡易書留ハガキ
    @service_code = 100201 
    # gui bang yubin (postcard se den trong 1 hoac 2 ngay)
    @deliver_code = 600001
    # in postcard co mau sac
    @color_code = 300004
    # in tren mot trang
    @page_number = 1
    #logo off
    @logo = 0
    #sender infor
    @sender = "〒460-0003\n愛知県名古屋市中区錦3-23-18\nニューサカエビル5F\nビットステーション株式会社"
    #title of mail when nexway response
    @title = "ハガキ確認"
    
    @pdf_file = Rails.root.join('public','postcard', "postcard.pdf")
    @csv_file = Rails.root.join('public','postcard', "postcard.csv")
  end

  def upload_file path_file, file_name
    get_id_registration if @time_get_id.nil? || Time.now - @time_get_id > 30.minutes ||  @id_registration.nil?
    file = File.read(path_file)
    file_binary = Base64.encode64(file)
    message = {
      "e:e_onTempID" => @id_registration,
      "e:e_onUploadFile" => file_binary,
      "e:e_onFileName" => file_name,
    }
    result = send_command :e_on_file_upload, message
    return nil if result.nil? 
    return result[:file_id]
  end

  def register_card file_id
    message = {
      "e:e_onTempID" => @id_registration,
      "e:e_onFileID" => file_id,
      "e:e_onServiceCode" => @service_code,
      "e:e_onDeliverCode" => @deliver_code,
      "e:e_onColorCode" => @color_code,
      "e:e_onPage" => @page_number,
    }
    result = send_command :e_on_pdf_register_card, message
    return false if result.nil?
    return true
  end

  def receiver_register file_id
    message = {
      "e:e_onTempID" => @id_registration,
      "e:e_onFileID" => file_id,
      "e:e_onServiceCode" => @service_code,
      "e:e_onDeliverCode" => @deliver_code,
    }

    result = send_command :e_on_receiver_register, message
    return nil if result.nil?
  
    return result[:count]
  end

  def order 
    # infor when nexway response
    note = @user.name + "様のハガキ"
    message = {
      "e:e_onTempID" => @id_registration,
      "e:e_onServiceCode" => @service_code,
      "e:e_onDeliverCode" => @deliver_code,
      "e:e_onSender" => @sender,
      "e:e_onLogoOption" => @logo,
      "e:e_onTitle" => @title,
      "e:e_onReferenceCode" => @user.member_id,
      "e:e_onNote" => note,
      "e:e_onMailTo" =>  ENV['SUPPORT_MAIL'],
    }

    result = send_command :e_on_order, message
    return nil if result.nil?
    return result[:order_no]
  end

  def convert_data_csv_to_hash data
    data_hash = {}
    if data && data.length > 0
      data_hash = {}
      index_of = data.index "\r\n"
      data_keys = data[0...index_of].gsub("\"", "").split(/,/)
      data_values = data[index_of...data.length].gsub("\"", "").gsub("\r\n", "").split(/,/)
      count = data_values.length
      for index in (1...count) do
        data_hash[data_keys[index]] = data_values[index]
      end
    end
    data_hash
  end

  
  def get_data_delivery order_id
    message = {
      "e:e_onOrderID" => order_id,
    }
    result = send_command :e_on_get_delivery_results, message
    return {} if result.nil?
    data = Base64.decode64(result[:result_csv]).encode("UTF-8", "Shift_JIS", :invalid => :replace, :undef => :replace) 

    # result delivery finis
    # "\"外部コード\",\"注文番号\",\"注文日\",\"発送日\",\"送信内容メモ\",\"請求明細コード\",\"備考\",\"製造番号\",\"お問い合わせ番号\",\"送達結果\",\"不達処理日\"\r
    # \n1501139991,17078962,2017/07/27,2017/07/27,ハガキ確認,1501139991,Tran Van Cong様のハガキ,17078962-00001,43769863373,1配達完了,\r\n"
   
    # result can not delivery
    # "\"外部コード\",\"注文番号\",\"注文日\",\"発送日\",\"送信内容メモ\",\"請求明細コード\",\"備考\",\"製造番号\",\"お問い合わせ番号\",\"送達結果\",\"不達処理日\"\r
    # \n1501140830,17078979,2017/07/27,2017/07/27,ハガキ確認,1501140830,Tran Van Cong様のハガキ,17078979-00001,43769863384,2配達完了 返還完了,2017/07/27\r\n"

    # result delivery
    #  "\"外部コード\",\"注文番号\",\"注文日\",\"発送日\",\"送信内容メモ\",\"請求明細コード\",\"備考\",\"製造番号\",\"お問い合わせ番号\",\"送達結果\",\"不達処理日\"\r\n"
    
    convert_data_csv_to_hash data
  end 

  def get_delivery_infor order_id
    data = get_data_delivery order_id
    return [data["お問い合わせ番号"], data["送達結果"]] if data["お問い合わせ番号"]
    nil
  end 

  def get_delivery_results order_id
    data = get_data_delivery order_id
    result = data["送達結果"]
    if result
      delivery_status = result[0].to_i
      return delivery_status
    end
    return 0
  end

  def check_postcard
    users = Member.where("account_class = 2 and post_card = 1 and order_postcard > 0")
    users.each do |user|
      result = get_delivery_results user.order_postcard 
      if user.order_postcard_company
        result_company = get_delivery_results user.order_postcard_company 
        if result_company == 1
          result = result_company
        end
      end
      next if result < 1 || result > 4
      case result
      when 1                                        #Sent postcard finis - 送達
        user.id_document.update_attribute(:is_address, 1)
        user.update_attribute(:account_class, 3)
        set_bonus user
      when 2                                        #不達(要再配達)
        user.update_attribute(:post_card, 2)  
      when 3                                        #不達(要住所確認)
        user.update_attribute(:post_card, 3)  
      when 4                                        #不達(その他)
        user.update_attribute(:post_card, 4)  
      end 
      PostcardMailer.postcard_mailer(user, result).deliver
    end
  end

  def set_bonus current_user
    if current_user.bonus != 1
      admin_account = Account.find_by(:member_id => 1,:currency => 3)
      bonus_fund = 1000
      referrer_bonus_fund = 1500
      if admin_account.balance > bonus_fund

        referrer_member = Member.find_by(id: current_user.referrer_member_id);
        if referrer_member
          #inviter
          referrer_member.accounts.find_by(:currency => 3).lock!.plus_funds referrer_bonus_fund, reason: Account::INVITE_BONUS, ref: nil
          admin_account.lock!.sub_funds referrer_bonus_fund, reason: Account::INVITE_BONUS, ref: nil

          #invited
          current_user.accounts.find_by(:currency => 3).lock!.plus_funds referrer_bonus_fund, reason: Account::INVITE_BONUS, ref: nil
          admin_account.lock!.sub_funds referrer_bonus_fund, reason: Account::INVITE_BONUS, ref: nil
        end

        admin_account.lock!.sub_funds bonus_fund, reason: Account::BONUS, ref: nil
        current_user.accounts.find_by(:currency => 3).lock!.plus_funds bonus_fund, reason: Account::BONUS, ref: nil
        # send mail
        TaocoinMailer.bonus(current_user.email).deliver
        # update bonus state
        current_user.update_attribute(:bonus, 1)
      end
    end
  end

  def check_id_registration
    @id_registration.nil? || Time.now - @time_get_id > 30.minutes
  end

  def send_command command, message = {}
    get_id_registration if check_id_registration && !message["e:e_onTempID"].nil?
    begin
        response = @client.call(command, message: message)
        result = response.body
        result = result[(command.to_s + "_response").to_sym][(command.to_s + "_result").to_sym]
        if result[:status] == "-1"
          @error = result[:error]
          return nil
        end
        return result
    rescue Exception => e
      @error = e
    end
    return nil
  end

  def get_id_registration
    @time_get_id = Time.now
    result = send_command :e_on_registration
    @id_registration = nil
    @id_registration = result[:temp_id] if !result.nil?
  end

  def encode_file file_name
    content = File.binread(Rails.root.join('public','postcard', file_name))
    encoded = Base64.encode64(content)
  end
end