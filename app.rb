# frozen_string_literal: true

require './lib/aws_s3_client'

class AwsSinatra < Sinatra::Application
  register Sinatra::ConfigFile

  config_file 'config/secrets.yml'

  get '/' do
    @author = settings.author
    erb :index
  end

  get '/buckets' do
    client = AwsS3Client.new(settings)
    @buckets = client.buckets
    erb :'buckets/index'
  end

  not_found do
    erb :'404'
  end
end
