require './lib/aws_s3_client'

class AwsSinatra < Sinatra::Application
  register Sinatra::ConfigFile

  config_file 'config/secrets.yml'

  get '/' do
    @author = settings.author
    erb :index
  end

  get '/aws' do
    aws_s3_client = AwsS3Client.client(settings)
    aws_s3_resource = AwsS3Client.resource(settings)
    @buckets =
    erb :aws
  end

  not_found do
    erb :'404'
  end
end