# frozen_string_literal: true

require 'active_record'
require 'yaml'
require 'erb'

module DatabaseConfig
  CONFIG_FILE = File.join(__dir__, 'database.yml')

  def self.load_config
    env = ENV.fetch('RACK_ENV', 'development')
    raw = ERB.new(File.read(CONFIG_FILE)).result
    YAML.safe_load(raw, aliases: true).fetch(env)
  end

  def self.establish!
    ActiveRecord::Base.establish_connection(load_config)
  end
end

DatabaseConfig.establish!
