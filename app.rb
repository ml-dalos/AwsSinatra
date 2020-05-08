# frozen_string_literal: true

require './lib/aws_s3_client'

class AwsSinatra < Sinatra::Application
  register Sinatra::ConfigFile
  register Sinatra::Flash
  use Rack::MethodOverride

  enable :sessions

  config_file 'config/secrets.yml'

  VALID_REGIONS = %w[
    eu-west-1
    us-west-1
    us-west-2
    us-east-2
    ap-south-1
    ap-southeast-1
    ap-southeast-2
    ap-northeast-1
    sa-east-1
    cn-north-1
    eu-central-1
  ]

  get '/' do
    @author = settings.author
    erb :index
  end

  get '/buckets' do
    client   = AwsS3Client.new(settings.aws)
    @buckets = client.buckets
    erb :'buckets/index'
  end

  get '/buckets/new' do
    erb :'buckets/new'
  end

  post '/buckets/new' do
    bucket = nil
    if valid_bucket_request?(request)
      bucket = AwsS3Client.new(settings.aws).new_bucket(request.params)
    end
  rescue Aws::S3::Errors::BucketAlreadyExists
    flash[:danger] = "Bucket with name #{request.params['bucket_name']} already exists!"
  rescue Aws::S3::Errors::BucketAlreadyOwnedByYou
    flash[:danger] = "Bucket with name #{request.params['bucket_name']} already owned by you!"
  rescue => e
    flash[:danger] = e.message
  ensure
    if bucket
      flash[:success] = "Bucket created!"
      redirect '/buckets', 302
    else
      redirect '/buckets/new', 302
    end
  end

  delete '/buckets' do
    if valid_bucket_request?(request)
      AwsS3Client.new(settings.aws).delete_bucket(request.params)
      flash[:success] = 'Bucket deleted!'
    end
  rescue => e
    flash[:danger] = e.message
  ensure
    redirect '/buckets', 302
  end

  not_found do
    erb :'404'
  end

  error do
    env['sinatra.error']
  end

  private

  def valid_bucket_request?(request)
    if request.params['bucket_name'].to_s.empty? || !VALID_REGIONS.include?(request.params['bucket_region'])
      flash[:danger] = 'Request invalid'
      false
    end
    true
  end
end
