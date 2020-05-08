# frozen_string_literal: true

class AwsS3Client
  VALID_REGIONS = %w[
    ap-south-1
    ap-northeast-2
    ap-southeast-1
    ap-southeast-2
    ap-northeast-1
    ca-central-1
    eu-central-1
    eu-west-1
    eu-west-2
    eu-west-3
    eu-north-1
    sa-east-1
    us-east-1
    us-east-2
    us-west-1
    us-west-2
  ]
  attr_reader :client, :resource

  def initialize(settings)
    @credentials = credentials(settings)
    @client      = Aws::S3::Client.new(region:      settings[:region],
                                       credentials: @credentials)
    @resource    = Aws::S3::Resource.new(client: client)
  end

  def buckets
    @resource.buckets.map.with_index(&method(:create_bucket_struct))
  end

  def new_bucket(params)
    raise 'Request invalid!' unless valid_bucket_params?(params)

    client = Aws::S3::Client.new(region: params['bucket_region'], credentials: @credentials)
    result = client.create_bucket(
      bucket:                      params['bucket_name'],
      create_bucket_configuration: { location_constraint: params['bucket_region'] }
    )
    if params['bucket_private']
      client.put_public_access_block(
        bucket: params['bucket_name'],
        public_access_block_configuration:
                {
                  block_public_acls:       true,
                  ignore_public_acls:      true,
                  block_public_policy:     true,
                  restrict_public_buckets: true,
                }
      )
    end
    result
  end

  def delete_bucket(params)
    raise 'Request invalid!' unless valid_bucket_params?(params)

    client = Aws::S3::Client.new(region: params['bucket_region'], credentials: @credentials)
    client.delete_bucket(bucket: params['bucket_name'])
  end

  def get_objects(bucket_name)
    region          = @client.get_bucket_location(bucket: bucket_name).location_constraint
    bucket_client   = Aws::S3::Client.new(region: region, credentials: @credentials)
    bucket_resource = Aws::S3::Resource.new(client: bucket_client)
    bucket_resource.bucket(bucket_name).objects.map.with_index do |object, index|
      # binding.pry
      {
        index: index.next,
        name: object.key,
        last_modified: object.last_modified,
        url: object.public_url,
        size: object.size,
        public:  object.acl.grants.any? {|grant| grant.grantee.uri == 'http://acs.amazonaws.com/groups/global/AllUsers' && grant.permission == 'READ'}
      }
    end
  end

  private

  def create_bucket_struct(bucket, index)
    region          = @client.get_bucket_location(bucket: bucket.name).location_constraint
    bucket_client   = Aws::S3::Client.new(region: region, credentials: @credentials)
    bucket_resource = Aws::S3::Resource.new(client: bucket_client)
    {
      name:          bucket.name,
      index:         index.next,
      region:        region,
      access:        get_bucket_access(bucket_client, bucket.name),
      creation_date: bucket.creation_date,
      total_objects: bucket_resource.bucket(bucket.name).objects.count
    }
  end

  def get_bucket_access(bucket_client, bucket_name)
    conf = bucket_client.get_public_access_block(bucket: bucket_name).public_access_block_configuration
    if conf.block_public_acls && conf.ignore_public_acls && conf.block_public_policy && conf.restrict_public_buckets
      'Not public'
    else
      'Objects can be public'
    end
  rescue Aws::S3::Errors::NoSuchPublicAccessBlockConfiguration
    'Objects can be public'
  end

  def credentials(settings)
    Aws::Credentials.new(settings[:access_key_id], settings[:secret_access_key])
  end

  def valid_bucket_params?(params)
    !params['bucket_name'].to_s.empty? && VALID_REGIONS.include?(params['bucket_region'])
  end
end
