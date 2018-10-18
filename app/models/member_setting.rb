class Security < ActiveRecord::Base
  belongs_to :member

  serialize :send_email, Hash
  serialize :two_factor, Hash
end
