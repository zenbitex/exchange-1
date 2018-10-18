class IdDocument < ActiveRecord::Base
  extend Enumerize
  include AASM
  include AASM::Locking

  has_one :id_document_infor, class_name: 'Asset::IdDocumentInfor', as: :attachable
  accepts_nested_attributes_for :id_document_infor

  has_one :id_document_file, class_name: 'Asset::IdDocumentFile', as: :attachable
  accepts_nested_attributes_for :id_document_file

  has_one :id_document_trade, class_name: 'Asset::IdDocumentTrade', as: :attachable
  accepts_nested_attributes_for :id_document_trade


  belongs_to :member

  validates_presence_of :name, :id_document_type, :id_document_number, :address, :id_bill_type, :foreign, :country, :job_type, :trade_purpose, :zipcode, allow_nil: true
  # validates_presence_of :country, :job_type, :trade_purpose
  validates_uniqueness_of :member
  enumerize :id_document_type, in: { driver_license: 0 ,id_card: 1, passport: 2, health_insurance: 3, seal_certificate: 4}
  enumerize :job_type, in: {office_worker: 0, employee: 1, civil_servant: 2, group_staff: 3, doctor: 4, lawyer: 5, faculty: 6, self_employed: 7,
                            part_time_job: 8, house_job: 9, student: 10, unemployed: 11, other: 12}
  enumerize :trade_purpose,     in: {purchase_virtual: 0, trading_due_price: 1, diversified_investment: 2, investment_time: 3, other: 4}
  enumerize :company_trade_purpose,     in: {purchase_virtual: 0, trading_due_price: 1, diversified_investment: 2, investment_time: 3, other: 4}
  enumerize :id_bill_type,     in: {bank_statement: 0, tax_bill: 1}
  enumerize :reason_reject, in: { inadequate_document: 0, incomplete_input: 1, image_unknown: 2}

  enumerize :foreign, in: { is_not: 0, is: 1}
  enumerize :manager_foreign, in: { is_not: 0, is: 1}
  enumerize :manager_role, in: { shareholder: 0, partner: 1, representative: 2}
  enumerize :type_role, in: { representative: 0, transaction_personnel: 1}

  alias_attribute :full_name, :name

  aasm do
    state :unverified, initial: true
    state :unaccepted
    state :verifying
    state :verified

    event :submit do
      transitions from: :unverified, to: :verifying
    end

    event :approve do
      transitions from: [:unverified, :verifying],  to: :verified
    end

    event :reject do
      transitions from: [:verifying, :verified],  to: :unverified
    end

  end

  def self.validate_birthdate(year, month, day)
    if month.to_i.in? [1,3,5,7,8,10,12]
      maxDay = 31
    elsif month.to_i.in? [4,6,9,11]
      maxDay = 30
    else
      maxDay = is_leapyear(year.to_i)? 29 : 28
    end
    return day.to_i <= maxDay
  end

  def self.is_leapyear(year)
    if (year%4 == 0 && year%100 != 0) || (year%400 == 0)
      return true
    else
      return false
    end
  end
end
