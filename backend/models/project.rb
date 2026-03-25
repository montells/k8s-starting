# frozen_string_literal: true

require 'active_record'

class Project < ActiveRecord::Base
  validates :name,   presence: true
  validates :status, inclusion: { in: %w[active inactive] }
end
