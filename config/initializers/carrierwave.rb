CarrierWave.configure do |config|
  config.fog_credentials = {
    :provider               => 'AWS',                        			# required
    :aws_access_key_id      => ENV['S3_ACCESS_KEY'],       				# required
    :aws_secret_access_key  => ENV['S3_SECRET_ACCESS_KEY'],  			# required
    :region                 => ENV['S3_REGION']				            # optional, defaults to 'us-east-1'
  }
  config.fog_directory  = ENV['S3_BUCKET_NAME']                     	# required
end
