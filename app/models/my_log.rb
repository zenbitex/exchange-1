class MyLog
  def self.kraken(message=nil)
    @my_log ||= Logger.new("#{Rails.root}/log/kraken.log")
    @my_log.debug(message) unless message.nil?
  end
end
