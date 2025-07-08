# db/seeds.rb
require 'json'

# Clear existing data in development
if Rails.env.development?
  puts "🧹 Cleaning up existing data..."
  Suggestion.destroy_all
  TranscriptMessage.destroy_all
  Incident.destroy_all
end

# Check for transcript file
transcript_file = Rails.root.join('transcript.json')

unless File.exist?(transcript_file)
  puts "❌ Transcript file not found!"
  puts "📁 Please copy your transcript file to: #{transcript_file}"
  puts "🔗 Original file: rootly_takehome_transcript_80_no_timestamps.json"
  exit
end

begin
  transcript_data = JSON.parse(File.read(transcript_file))
rescue JSON::ParserError => e
  puts "❌ Invalid JSON in transcript file: #{e.message}"
  exit
end

# Validate transcript structure
unless transcript_data['meeting_transcript'].is_a?(Array)
  puts "❌ Invalid transcript format. Expected 'meeting_transcript' array."
  exit
end

puts "📊 Creating incident from #{transcript_data['meeting_transcript'].length} messages..."

# Create the incident
incident = Incident.create!(
  title: "Database Saturation - Web Tier Error Spike",
  description: "High error rates and 502 responses caused by database performance issues following Deploy #341",
  status: :active
)

# Create transcript messages in sequential order
transcript_data['meeting_transcript'].each_with_index do |message_data, index|
  TranscriptMessage.create!(
    incident: incident,
    speaker: message_data['speaker'],
    content: message_data['text'],
    sequence_number: index
  )
end

puts "✅ Successfully created incident: #{incident.title}"
puts "📝 Messages: #{incident.transcript_messages.count}"
puts "⏱️  Estimated replay time: #{(incident.total_messages * incident.processing_interval_seconds / 60).round(1)} minutes"
puts ""
puts "Next steps:"
puts "   1. Start Redis: redis-server"
puts "   2. Start Sidekiq: bundle exec sidekiq"
puts "   3. Start Rails: rails server"
puts "   4. Visit: http://localhost:3000/incidents/#{incident.id}"
puts "   5. Click 'Start Replay' to begin AI analysis"