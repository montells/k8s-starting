# frozen_string_literal: true

require 'httparty'

module BackendClient
  # Fetches data from the backend API
  # @param backend_url [String] The base URL of the backend service
  # @param path [String] The API path to call (default: '/')
  # @return [Hash] The parsed JSON response or error information
  def self.fetch(backend_url, path = '/')
    url = "#{backend_url}#{path}"
    
    response = HTTParty.get(url)
    
    if response.success?
      response.parsed_response
    else
      { error: "HTTP #{response.code}: #{response.message}" }
    end
  rescue StandardError => e
    { error: e.message }
  end
end
