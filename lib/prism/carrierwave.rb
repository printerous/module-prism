CarrierWave.configure do |config|
  config.fog_provider    = 'fog/aws'
  config.fog_credentials = {
    provider:              'AWS',
    aws_access_key_id:     ENV.fetch('AWS_S3_KEY', 'KEY_HERE'),
    aws_secret_access_key: ENV.fetch('AWS_S3_SECRET', 'SECRET_HERE'),
    region:                ENV.fetch('AWS_S3_REGION', 'REGION_HERE')
  }

  config.fog_directory  = ENV['AWS_S3_BUCKET']
  config.fog_attributes = { cache_control: "public, max-age=#{ 365.day.to_i }" }
end
