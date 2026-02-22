# frozen_string_literal: true

require 'sinatra'

# Configure server to run on port 8080
set :port, 8080
set :bind, '0.0.0.0'

# Root route - renders the index template
get '/' do
  @message = ENV.fetch('APP_MESSAGE', 'Hola desde K8s!')
  @environment = ENV.fetch('APP_ENV', 'development')
  @pod_name = ENV.fetch('POD_NAME', 'local-container')
  @hostname = `hostname`.strip
  
  erb :index
end

# Health check endpoint
get '/health' do
  status 200
  'OK'
end
