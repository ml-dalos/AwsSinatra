# frozen_string_literal: true

require './lib/aws_s3_client'

class AwsSinatra < Sinatra::Application
  register Sinatra::ConfigFile
  register Sinatra::Flash
  use Rack::MethodOverride

  enable :sessions

  config_file 'config/secrets.yml'

  use Rack::Auth::Basic, "Protected Area" do |username, password|
    username == settings.auth[:username] && password == settings.auth[:password]
  end

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
    bucket = AwsS3Client.new(settings.aws).new_bucket(request.params)
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
    AwsS3Client.new(settings.aws).delete_bucket(request.params)
    flash[:success] = 'Bucket deleted!'
  rescue => e
    flash[:danger] = e.message
  ensure
    redirect '/buckets', 302
  end

  get '/buckets/:name' do
    @objects = AwsS3Client.new(settings.aws).get_objects(params['name'])
    @bucket  = AwsS3Client.new(settings.aws).resource.bucket(params['name'])
    @region = AwsS3Client.new(settings.aws).client.get_bucket_location(bucket: @bucket.name).location_constraint
    erb :'buckets/show'
  rescue => e
    flash[:danger] = e.message
    redirect '/buckets', 302
  end

  post '/objects/new' do
    if params['file'].nil? || params['file']['filename'].to_s.empty?
      flash[:danger] = 'Invalid filename'
      redirect back
    end
    filename = params['file']['filename']
    tempfile = params['file']['tempfile']
    bucket   = AwsS3Client.new(settings.aws, region: params['bucket_region']).resource.bucket(params['bucket_name'])

    obj = bucket.object(filename)
    if obj.upload_file(tempfile)
      flash[:success] = 'File uploaded!'
    else
      flash[:danger] = 'File not uploaded!'
    end
  rescue => e
    flash[:danger] = e.message
  ensure
    redirect back
  end


  # TODO:
  # configure upload form and delete/change access
  not_found do
    erb :'404'
  end

  error do
    env['sinatra.error']
  end
end
