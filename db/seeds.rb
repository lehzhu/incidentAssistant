# db/seeds.rb
require 'json'

# Clear existing data in development
if Rails.env.development?
  puts "🧹 Cleaning up existing data..."
  Suggestion.destroy_all
  TranscriptMessage.destroy_all
  Incident.destroy_all
end

# Sample transcript data for testing
sample_transcript = [
  {
    "speaker" => "Alice",
    "message" => "We're getting reports that the main API is down. Users can't log in."
  },
  {
    "speaker" => "Bob", 
    "message" => "I'm seeing 500 errors in the logs. Started about 10 minutes ago."
  },
  {
    "speaker" => "Alice",
    "message" => "What was the last deployment? Could this be related to the release we pushed this morning?"
  },
  {
    "speaker" => "Charlie",
    "message" => "The deployment was at 9 AM. This issue started around 9:15 AM, so it could be related."
  },
  {
    "speaker" => "Bob",
    "message" => "I need to check the database connections. The error mentions connection timeouts."
  },
  {
    "speaker" => "Alice",
    "message" => "We should roll back the deployment while we investigate the root cause."
  },
  {
    "speaker" => "Dave",
    "message" => "Customer support is getting flooded with complaints. What's our ETA for resolution?"
  },
  {
    "speaker" => "Charlie",
    "message" => "Working on the rollback now. Should take about 5 minutes to complete."
  },
  {
    "speaker" => "Bob",
    "message" => "Found the issue - new database migration is causing connection pool exhaustion."
  },
  {
    "speaker" => "Alice",
    "message" => "Rollback completed. API is responding normally now. We need to investigate the migration issue."
  },
  {
    "speaker" => "Charlie",
    "message" => "I'll create a post-mortem ticket to analyze what went wrong with the migration."
  },
  {
    "speaker" => "Dave",
    "message" => "Confirmed - customer reports are decreasing. Issue appears resolved."
  }
]

# Create a sample incident
incident = Incident.create!(
  title: "API Outage - Login Service Down",
  description: "Main API experiencing 500 errors preventing user logins. Appears related to recent deployment.",
  status: "active"
)

# Create transcript messages
sample_transcript.each_with_index do |message, index|
  incident.transcript_messages.create!(
    speaker: message["speaker"],
    content: message["message"],
    sequence_number: index + 1
  )
end

puts "Created sample incident: #{incident.title}"
puts "Transcript has #{sample_transcript.length} messages"
puts "Visit http://localhost:3000/incidents/#{incident.id} to start replay"
