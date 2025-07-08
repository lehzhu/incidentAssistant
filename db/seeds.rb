# db/seeds.rb
require 'json'

# Clear existing data in development
if Rails.env.development?
  puts "🧹 Cleaning up existing data..."
  Suggestion.destroy_all
  TranscriptMessage.destroy_all
  Incident.destroy_all
end

# Load real transcript data from JSON file
transcript_file = File.read(Rails.root.join('transcript.json'))
transcript_data = JSON.parse(transcript_file)
sample_transcript = transcript_data['meeting_transcript']

# Create incident from real transcript
incident = Incident.create!(
  title: "Web Tier Error Rate Spike - Homepage Unavailable",
  description: "High error rates on web tier causing 502 errors. Analytics product also affected. Database showing 100% CPU utilization.",
  status: "active"
)

# Create transcript messages from real data
sample_transcript.each_with_index do |message, index|
  incident.transcript_messages.create!(
    speaker: message["speaker"],
    content: message["text"],
    sequence_number: index + 1
  )
end

puts "Created sample incident: #{incident.title}"
puts "Transcript has #{sample_transcript.length} messages"
puts "Visit http://localhost:3000/incidents/#{incident.id} to start replay"
