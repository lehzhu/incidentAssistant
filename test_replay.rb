#!/usr/bin/env ruby
require 'bundler/setup'
require_relative 'config/environment'

# Test if we can start a replay programmatically
incident = Incident.find(6)
puts "Testing replay for incident: #{incident.title}"
puts "Status: #{incident.status}"
puts "Replay completed: #{incident.replay_completed?}"

# Clear old suggestions
incident.suggestions.destroy_all
puts "Cleared #{incident.suggestions.count} suggestions"

# Test the job directly
puts "\nTesting IncidentReplayJob..."
begin
  IncidentReplayJob.new.perform(incident.id)
  puts "Job completed successfully!"
rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace.first(5)
end
