class FcmToken < ActiveRecord::Base
  belongs_to :member

  scope :enabled, -> { where(enable: true) }

  def enable!
    update enable: true
  end

  def disable!
    update enable: false
  end
end
