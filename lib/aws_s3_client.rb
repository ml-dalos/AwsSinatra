module AwsS3Client
  def self.client(settings)
    Aws::S3::Client.new(region: settings.aws[:region], credentials: credentials(settings))
  end

  def self.resource(settings)
    Aws::S3::Resource.new(client: client(settings))
  end

  private

  def self.credentials(settings)
    Aws::Credentials.new(settings.aws[:access_key_id], settings.aws[:secret_access_key])
  end

end