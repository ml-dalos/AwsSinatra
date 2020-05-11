module AWS
  class Client

    attr_reader :client, :region, :resource

    def initialize(secrets, region: secrets[:region])
      @credentials = credentials(secrets)
      @region = region
      @client = Aws::S3::Client.new(region: region, credentials: @credentials)
      @resource = Aws::S3::Resource.new(client: @client)
    end

    def buckets
      @buckets ||= @resource.buckets.map(&method(:bucket))
    end

    private

    def credentials(secrets)
      raise 'AWS access key id not found!' if secrets[:access_key_id].to_s.empty?
      raise 'AWS secret access key not found!' if secrets[:secret_access_key].to_s.empty?

      Aws::Credentials.new(secrets[:access_key_id], secrets[:secret_access_key])
    end

    def bucket(bucket)
      region = @client.get_bucket_location(bucket: bucket.name).location_constraint
      bucket_client = Aws::S3::Client.new(region: region, credentials: @credentials)
      bucket_resource = Aws::S3::Resource.new(client: bucket_client)
      Bucket.new(resource: bucket_resource, region: region, template: bucket)
    end
  end
end