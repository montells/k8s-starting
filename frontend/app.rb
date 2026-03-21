# frozen_string_literal: true

require 'sinatra'
require_relative 'visit_counter'
require_relative 'version'
require_relative 'backend_client'

# Configure server to run on port 8080
set :port, 8080
set :bind, '0.0.0.0'

# Initialize VisitCounter
visit_counter = VisitCounter.new(ENV.fetch('VISIT_COUNT_FILE', '/data/visits.txt'))

allowed_hosts = ENV.fetch("ALLOWED_HOSTS", "localhost")

unless allowed_hosts.empty?
  set :host_authorization, {
    permitted_hosts: allowed_hosts.split(",")
  }
end

# Root route - renders the index template
get '/' do
  # Increment the visit count
  @visit_count = visit_counter.increment

  @version = VERSION::STRING
  @message = ENV.fetch('APP_MESSAGE', 'Hola desde K8s!')
  @environment = ENV.fetch('APP_ENV', 'development')
  @pod_name = ENV.fetch('POD_NAME', 'local-container')
  @hostname = `hostname`.strip
  
  # Fetch backend response
  backend_url = ENV.fetch('BACKEND_URL', 'http://localhost:8081')
  @backend_response = BackendClient.fetch(backend_url, '/')
  
  erb :index
end

# Health check endpoint
get '/health' do
  status 200
  'OK'
end
