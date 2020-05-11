module AWS
  class Bucket
    PUBLIC_ACCESS_BLOCK_CONFIGURATION = {
      block_public_acls:       true,
      ignore_public_acls:      true,
      block_public_policy:     true,
      restrict_public_buckets: true,
    }

    attr_reader :client, :resource, :access, :creation_date, :name, :region, :total_objects

    def self.create(client, params = {})
      region_configuration = { location_constraint: params[:region] }
      bucket = client.client.create_bucket(
        bucket: params[:name],
        create_bucket_configuration: region_configuration)

      if params[:private]
        client.client.put_public_access_block(
          bucket: params[:name],
          public_access_block_configuration: PUBLIC_ACCESS_BLOCK_CONFIGURATION
        )
      end
      bucket
    end

    def self.delete(client, params = {})
      client.client.delete_bucket(bucket: params[:name])
    end

    def initialize(resource:, region:, template:)
      @name = template.name
      @region = region
      @resource = resource
      @client = resource.client
      @creation_date = template.creation_date
      @total_objects = @resource.bucket(@name).objects.count
      @access = public_access
      @bucket = @resource.bucket(template.name)
    end

    def objects
      @bucket.objects.map { |object| Object.new(bucket: self, template: object) }
    end

    private

    def public_access
      conf = @client.get_public_access_block(bucket: @name).public_access_block_configuration
      if conf.block_public_acls && conf.ignore_public_acls &&
         conf.block_public_policy && conf.restrict_public_buckets
        'Not public'
      else
        'Objects can be public'
      end
    rescue Aws::S3::Errors::NoSuchPublicAccessBlockConfiguration
      'Objects can be public'
    end
  end
end