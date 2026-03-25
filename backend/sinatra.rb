# frozen_string_literal: true

require 'sinatra'
require_relative 'version'
require_relative 'config/database'
require_relative 'services/project_finder'

set :port, 8081
set :bind, '0.0.0.0'

allowed_hosts = ENV.fetch("ALLOWED_HOSTS", "sinatra-backend-svc")

unless allowed_hosts.empty?
  set :host_authorization, {
    permitted_hosts: allowed_hosts.split(",")
  }
end

# Set JSON content type globally for all responses
before do
  content_type :json
end

get '/' do
  {
    message: "ok",
  }.to_json
end

get '/health' do
  status 200
  {
    status: "healthy",
    version: VERSION::STRING,
  }.to_json
end

get '/project/:id' do
  unless params[:id] =~ /\A\d+\z/
    $stdout.puts "[ERROR] Invalid project ID format: #{params[:id]}"
    halt 400, { error: 'Invalid project ID format' }.to_json
  end

  result = ProjectFinder.new.find(params[:id].to_i)

  if result[:success]
    status 200
    { project: result[:project] }.to_json
  else
    status result[:status]
    { error: result[:error] }.to_json
  end
end