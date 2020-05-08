# frozen_string_literal: true

class AwsS3Client
  attr_reader :client, :resource

  def initialize(settings)
    @credentials = credentials(settings)
    @client = Aws::S3::Client.new(region: settings.aws[:region],
                                  credentials: @credentials)
    @resource = Aws::S3::Resource.new(client: client)
  end

  def buckets
    @resource.buckets.map.with_index(&method(:create_bucket_struct))
  end

  private

  def create_bucket_struct(bucket, index)
    region = @client.get_bucket_location(bucket: bucket.name).location_constraint
    bucket_client = Aws::S3::Client.new(region: region, credentials: @credentials)
    bucket_resource = Aws::S3::Resource.new(client: bucket_client)
    {
      name: bucket.name,
      index: index.next,
      region: region,
      access: get_bucket_access(bucket_client, bucket.name),
      creation_date: bucket.creation_date,
      total_objects: bucket_resource.bucket(bucket.name).objects.count
    }
  end

  def get_bucket_access(bucket_client, bucket_name)
    bucket_client.get_public_access_block(bucket: bucket_name).public_access_block_configuration
  rescue Aws::S3::Errors::NoSuchPublicAccessBlockConfiguration
    Aws::S3::Types::PublicAccessBlockConfiguration.new
  end

  def credentials(settings)
    Aws::Credentials.new(settings.aws[:access_key_id], settings.aws[:secret_access_key])
  end
end
