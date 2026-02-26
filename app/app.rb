# frozen_string_literal: true

require 'sinatra'
require 'fileutils'

# Configure server to run on port 8080
set :port, 8080
set :bind, '0.0.0.0'

# Path where the visit count will be stored
VISIT_COUNT_FILE = ENV.fetch('VISIT_COUNT_FILE', '/data/visits.txt')

# Read current visit count from file
def get_visit_count
  return nil unless File.exist?(VISIT_COUNT_FILE)
  count = File.read(VISIT_COUNT_FILE).strip
  count.empty? ? nil : count.to_i
rescue => e
  puts "Error reading visit count: #{e.message}"
  nil
end

# Write visit count to file
# Creates the file if it doesn't exist
def save_visit_count(count)
  # Ensure the directory exists
  dir = File.dirname(VISIT_COUNT_FILE)
  FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
  
  # Write the count to file (creates if doesn't exist)
  File.write(VISIT_COUNT_FILE, count.to_s)
rescue => e
  puts "Error saving visit count: #{e.message}"
  false
end

allowed_hosts = ENV.fetch("ALLOWED_HOSTS", "localhost")

unless allowed_hosts.empty?
  set :host_authorization, {
    permitted_hosts: allowed_hosts.split(",")
  }
end

# Root route - renders the index template
get '/' do
  # Try to read existing count, start at 0 if file doesn't exist or has errors
  current_count = get_visit_count
  current_count = 0 if current_count.nil?
  
  # Increment the count
  new_count = current_count + 1
  
  # Try to save, but continue even if it fails
  save_visit_count(new_count)
  
  # Set the count for display (nil if there was an error)
  @visit_count = get_visit_count
  
  @version = '1.0.0'
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
