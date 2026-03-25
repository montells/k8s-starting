# frozen_string_literal: true

require_relative '../models/project'

class ProjectFinder
  def find(id)
    project = Project.find(id)
    { success: true, project: project.as_json(only: %i[id name description status]) }
  rescue ActiveRecord::RecordNotFound
    $stdout.puts "[ERROR] Project not found: id=#{id}"
    { success: false, status: 404, error: 'Project not found' }
  rescue ActiveRecord::NoDatabaseError => e
    $stdout.puts "[ERROR] Database does not exist: #{e.message}"
    { success: false, status: 503, error: 'Database does not exist' }
  rescue ActiveRecord::DatabaseConnectionError => e
    $stdout.puts "[ERROR] Database connection failed: #{e.message}"
    { success: false, status: 503, error: 'Database connection failed' }
  rescue ActiveRecord::ActiveRecordError => e
    $stdout.puts "[ERROR] Database error: #{e.message}"
    { success: false, status: 503, error: 'Database error' }
  end
end
