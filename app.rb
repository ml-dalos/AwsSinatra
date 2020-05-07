class AwsSinatra < Sinatra::Application

  get '/' do
    'Hello world'
    erb :index
  end

  not_found do
    erb '404'
  end

end