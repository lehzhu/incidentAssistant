require 'set'
require 'ostruct'

class StreamTranscriptJob
  include Sidekiq::Worker

  def perform(incident_id)
    incident = Incident.find(incident_id)
    @ai_analyzer = AiAnalyzer.new
    
    # Load transcript data
    transcript_path = Rails.root.join('transcript.json')
    transcript_data = JSON.parse(File.read(transcript_path))
    messages = transcript_data['meeting_transcript']
    
    # Calculate timing: stream over 60 seconds
    total_messages = messages.length
    interval = 60.0 / total_messages # seconds per message
    
    # Track processed messages for AI analysis
    @processed_messages = []
    # Track created suggestions to avoid duplicates
    @created_suggestions = Set.new
    
    messages.each_with_index do |message, index|
      # Convert message format for our models
      transcript_message = OpenStruct.new(
        speaker: message['speaker'],
        content: message['text']
      )
      @processed_messages << transcript_message
      
      # Send transcript message
      ActionCable.server.broadcast(
        "incident_#{incident_id}_suggestions",
        {
          type: 'transcript_message',
          data: {
            speaker: message['speaker'],
            text: message['text'],
            timestamp: Time.current.to_i,
            sequence: index + 1,
            total: total_messages
          }
        }
      )
      
      # Analyze messages with AI every few messages (to avoid too many API calls)
      if should_analyze_now?(index)
        analyze_and_broadcast_suggestions(incident_id, index)
      end
      
      # Sleep until next message
      sleep(interval)
    end
    
    # Final analysis with all messages
    analyze_and_broadcast_suggestions(incident_id, messages.length - 1)
    
    # Send completion message
    ActionCable.server.broadcast(
      "incident_#{incident_id}_suggestions",
      {
        type: 'replay_complete',
        data: {
          message: 'Transcript replay completed',
          timestamp: Time.current.to_i
        }
      }
    )
    
    # Clear the job running flag
    Rails.cache.delete("transcript_job_running_#{incident_id}")
  rescue => e
    Rails.logger.error "StreamTranscriptJob failed: #{e.message}"
    Rails.cache.delete("transcript_job_running_#{incident_id}")
    raise
  end
  
  private
  
  def should_analyze_now?(index)
    # Analyze every 5 messages, or at key points in the conversation
    (index + 1) % 5 == 0 || index == 2 # Start early analysis
  end
  
  def analyze_and_broadcast_suggestions(incident_id, current_index)
    # Only analyze if we have enough messages
    return if @processed_messages.length < 3
    
    incident = Incident.find(incident_id)
    
    # Get suggestions from AI
    ai_suggestions = @ai_analyzer.analyze_transcript_chunk(@processed_messages)
    
    # Create and broadcast each suggestion
    ai_suggestions.each do |ai_suggestion|
      # Create a unique key for deduplication
      suggestion_key = "#{ai_suggestion['category']}_#{ai_suggestion['title']}"
      
      # Skip if we've already created this suggestion
      next if @created_suggestions.include?(suggestion_key)
      
      # Create suggestion in database
      suggestion = incident.suggestions.create!(
        category: ai_suggestion['category'],
        title: ai_suggestion['title'],
        description: ai_suggestion['description'],
        status: 'pending'
      )
      
      # Mark as created
      @created_suggestions.add(suggestion_key)
      
      # Broadcast the created suggestion
      ActionCable.server.broadcast(
        "incident_#{incident_id}_suggestions",
        {
          type: 'ai_suggestion',
          data: {
            suggestion: suggestion.as_json,
            timestamp: Time.current.to_i,
            related_to: current_index + 1
          }
        }
      )
    end
  rescue => e
    Rails.logger.error "Failed to analyze transcript chunk: #{e.message}"
  end
  
end
