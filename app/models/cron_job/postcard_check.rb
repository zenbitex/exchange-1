module CronJob
  class PostcardCheck
    def self.handle
      postcard = Postcard.new
      postcard.check_postcard
    end
  end
end
