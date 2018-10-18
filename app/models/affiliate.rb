class Affiliate < ActiveRecord::Base
  scope :recent, -> {order(created_at: :desc)}

  class << self
    def search_affiliate(field: nil, term: nil)
      result = case field
        when 'id'
           where('affiliates.id LIKE ?', "%#{term}%")
        when 'bonus'
           where('affiliates.bonus LIKE ?', "%#{term}%")
        else
          all
      end
    end
  end
end
