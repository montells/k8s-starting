# frozen_string_literal: true

require 'fileutils'

class VisitCounter
  def initialize(file_path)
    @file_path = file_path
  end

  # Read current visit count from file
  def current_count
    return 0 unless File.exist?(@file_path)

    count = File.read(@file_path).strip
    count.empty? ? 0 : count.to_i
  rescue => e
    puts "Error reading visit count: #{e.message}"
    0
  end

  # Increment the visit count and save it
  def increment
    new_count = current_count + 1
    save_count(new_count)
    new_count
  end

  private

  # Write visit count to file
  def save_count(count)
    dir = File.dirname(@file_path)
    FileUtils.mkdir_p(dir) unless Dir.exist?(dir)

    File.write(@file_path, count.to_s)
  rescue => e
    puts "Error saving visit count: #{e.message}"
  end
end