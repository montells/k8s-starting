# frozen_string_literal: true

require 'sinatra'
require_relative 'version'

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