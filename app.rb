# frozen_string_literal: true

require './lib/aws/aws'

class AwsSinatra < Sinatra::Application
  register Sinatra::ConfigFile
  register Sinatra::Flash
  use Rack::MethodOverride

  enable :sessions

  config_file 'config/secrets.yml'

  use Rack::Auth::Basic, 'Protected Area' do |username, password|
    username == settings.auth[:username] && password == settings.auth[:password]
  end

  get '/' do
    @author = settings.author
    erb :index
  rescue => e
    flash[:danger] = e.message
    redirect '/error', 302
  end

  get '/buckets' do
    client   = AWS::Client.new(settings.aws)
    @buckets = client.buckets
    erb :'buckets/index'
  rescue => e
    flash[:danger] = e.message
    redirect '/', 302
  end

  get '/buckets/new' do
    erb :'buckets/new'
  rescue => e
    flash[:danger] = e.message
    redirect '/buckets', 302
  end

  post '/buckets/new' do
    client = AWS::Client.new(settings.aws, region: params[:bucket][:region])
    AWS::Bucket.create(client, name: params[:bucket][:name], private: params[:bucket][:private])
    flash[:success] = "Bucket created!"
  rescue Aws::S3::Errors::BucketAlreadyExists
    flash[:danger] = "Bucket with name #{request.params[:bucket][:name]} already exists!"
  rescue Aws::S3::Errors::BucketAlreadyOwnedByYou
    flash[:danger] = "Bucket with name #{request.params[:bucket][:name]} already owned by you!"
  rescue => e
    flash[:danger] = e.message
  ensure
    if flash.next[:success]
      redirect '/buckets', 302
    else
      redirect '/buckets/new', 302
    end
  end

  delete '/buckets' do
    client = AWS::Client.new(settings.aws, region: params[:bucket][:region])
    AWS::Bucket.delete(client, name: params[:bucket][:name])
    flash[:success] = 'Bucket deleted!'
  rescue => e
    flash[:danger] = e.message
  ensure
    redirect '/buckets', 302
  end

  get '/buckets/:name' do
    client   = AWS::Client.new(settings.aws)
    @bucket = client.buckets.find { |bucket| bucket.name == params[:name] }
    @objects = @bucket.objects
    erb :'buckets/show'
  rescue => e
    flash[:danger] = e.message
    redirect '/buckets', 302
  end

  post '/objects/new' do
    bucket = AWS::Client.new(settings.aws, region: params[:bucket][:region]).resource.bucket(params[:bucket][:name])
    if AWS::Object.create(bucket, tempfile: params[:file][:tempfile], filename: params[:file][:filename])
      flash[:success] = 'File uploaded!'
    else
      flash[:danger] = 'File not uploaded!'
    end
  rescue => e
    flash[:danger] = e.message
  ensure
    redirect back
  end

  delete '/objects' do
    bucket = AWS::Client.new(settings.aws, region: params[:bucket][:region]).resource.bucket(params[:bucket][:name])
    AWS::Object.delete(bucket, name: params[:object][:name])
    flash[:success] = 'Object deleted!'
  rescue => e
    flash[:danger] = e.message
  ensure
    redirect back, 302
  end

  post '/objects/edit' do
    client = AWS::Client.new(settings.aws, region: params[:bucket][:region])
    access = params[:object][:public] == 'true' ? 'private' : 'public-read'
    AWS::Object.change_access(client, access: access, bucket: params[:bucket][:name], key: params[:object][:name])
  rescue => e
    flash[:danger] = e.message
  ensure
    redirect back
  end

  not_found do
    erb :'404'
  end

  get '/error' do
    erb :'500'
  end

  error do
    env['sinatra.error']
  end
end
