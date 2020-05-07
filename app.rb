class AwsSinatra < Sinatra::Application
  register Sinatra::ConfigFile

  config_file 'config/secrets.yml'

  get '/' do
    @author = settings.author
    erb :index
  end

  not_found do
    erb :'404'
  end
end