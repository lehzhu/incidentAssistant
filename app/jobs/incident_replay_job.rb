require 'set'

class IncidentReplayJob
  include Sidekiq::Worker
  sidekiq_options retry: false # Don't retry this job if it fails midway

  def perform(incident_id)
    @incident = Incident.find(incident_id)
    @ai_analyzer = AiAnalyzer.new
    
    # Read from the database, not a static file
    messages = @incident.transcript_messages.ordered
    return if messages.empty? # Nothing to do

    # Use the interval logic from your Incident model
    interval = @incident.processing_interval_seconds
    total_messages = @incident.total_messages
    
    @created_suggestions = Set.new # For deduplication
    
    messages.each_with_index do |message, index|
      # Broadcast the message from the database
      broadcast_transcript_message(message, index, total_messages)
      
      # Analyze based on context up to this point
      if should_analyze_now?(index, total_messages)
        # Pass DB records to the analyzer
        context_messages = @incident.transcript_messages.up_to_sequence(message.sequence_number).last(10)
        analyze_and_broadcast_suggestions(context_messages, index)
      end
      
      sleep(interval)
    end
    
    broadcast_completion
    
    @incident.update!(status: :resolved, replay_completed: true)
    Rails.cache.delete("incident_replay_running_#{@incident.id}")
  rescue => e
    Rails.logger.error "IncidentReplayJob for incident #{incident_id} failed: #{e.message}"
    Rails.cache.delete("incident_replay_running_#{@incident.id}")
    # Optional: Mark incident as failed
    # @incident&.update(status: :failed) 
    raise
  end
  
  private
  
  def should_analyze_now?(index, total_messages)
    # Analyze less frequently to avoid too many suggestions
    # Analyze at: message 10, 20, 30, 40, etc. and at the end
    ((index + 1) % 10 == 0 && index > 5) || index == total_messages - 1
  end
  
  def broadcast_transcript_message(message, index, total_messages)
    ActionCable.server.broadcast(
      "incident_#{@incident.id}_suggestions",
      {
        type: 'transcript_message',
        data: {
          speaker: message.speaker,
          text: message.content,
          timestamp: Time.current.to_i,
          sequence: index + 1,
          total: total_messages
        }
      }
    )
  end

  def analyze_and_broadcast_suggestions(context_messages, current_index)
    # Get suggestions from AI
    ai_suggestions = @ai_analyzer.analyze_transcript_chunk(context_messages)
    
    ai_suggestions.each do |ai_suggestion|
      # Deduplication logic
      suggestion_key = "#{ai_suggestion['category']}_#{ai_suggestion['title']}"
      next if @created_suggestions.include?(suggestion_key)
      
      # Create suggestion in database
      suggestion = @incident.suggestions.create!(
        category: ai_suggestion['category'],
        title: ai_suggestion['title'],
        description: ai_suggestion['description'],
        status: :pending,
        importance_score: ai_suggestion['importance'] || 50
      )
      @created_suggestions.add(suggestion_key)
      
      # Broadcast the created suggestion
      ActionCable.server.broadcast(
        "incident_#{@incident.id}_suggestions",
        {
          type: 'ai_suggestion',
          data: { suggestion: suggestion.as_json(methods: :important?) } 
        }
      )
    end
  rescue => e
    Rails.logger.error "Failed to analyze transcript chunk: #{e.message}"
  end

  def broadcast_completion
    ActionCable.server.broadcast(
      "incident_#{@incident.id}_suggestions",
      {
        type: 'replay_complete',
        data: {
          message: 'Transcript replay completed',
          timestamp: Time.current.to_i
        }
      }
    )
  end
  
end
