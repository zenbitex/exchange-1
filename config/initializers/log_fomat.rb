if Rails.env.production?
	Rails.logger = ActiveSupport::Logger.new "log/production.log"
	Rails.logger.formatter = proc{|severity,datetime,progname,msg|
		if msg && msg != "" && !msg.index("OWcwah2EYIvxd1wwkECPX9Xlwp2uTRWTFyNv4QFD") && !msg.index("rbenv/versions/2.2.1/lib/ruby/gems/2.2.0/gems/grape-0.7.0/lib/grape/") && !msg.index("source: \"APIv2\"") && !msg.index("/api/")
	  	"[#{datetime.strftime("%Y-%m-%d %H:%M:%S")}] [#{severity}]: #{msg}\n"
	  end
	}
end
