# frozen_string_literal: true

require 'sinatra'
require_relative 'version'

set :port, 8081
set :bind, '0.0.0.0'

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