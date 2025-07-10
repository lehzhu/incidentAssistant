class IncidentReplayJob < ApplicationJob
  queue_as :default
  
  def perform(incident_id)
    @incident = Incident.find(incident_id)
    @ai_analyzer = AiAnalyzer.new
    
    Rails.logger.info "Starting replay for incident #{@incident.id} with #{@incident.total_messages} messages"
    
    process_messages_sequentially
    
    @incident.update!(status: :resolved)
    broadcast_completion
    
    Rails.logger.info "Completed replay for incident #{@incident.id}"
  end
  
  private
  
  def process_messages_sequentially
    @incident.transcript_messages.ordered.each_with_index do |current_message, index|
      Rails.logger.debug "Processing message #{index + 1}/#{@incident.total_messages}: #{current_message.speaker}"
      
      # First, broadcast the transcript message for real-time display
      broadcast_transcript_message(current_message, index)
      
      # CRITICAL: Only use messages up to current point (streaming simulation)
      context_messages = @incident.transcript_messages
                                  .up_to_sequence(current_message.sequence_number)
                                  .ordered
                                  .last(8)  # Use last 8 messages as context window
      
      # Generate AI suggestions based on context (only if we have enough context)
      if context_messages.count >= 3
        suggestions = @ai_analyzer.analyze_transcript_chunk(context_messages)
        
        # Create and broadcast suggestions
        suggestions.each do |suggestion_data|
          create_and_broadcast_suggestion(suggestion_data)
        end
      end
      
      # Wait before processing next message (simulate real-time)
      sleep(@incident.processing_interval_seconds)
    end
  end
  
  def broadcast_transcript_message(message, index)
    # Broadcast transcript message for real-time display
    ActionCable.server.broadcast(
      "incident_#{@incident.id}_suggestions",
      {
        type: 'transcript_message',
        data: {
          speaker: message.speaker,
          text: message.content,
          timestamp: Time.current.to_i,
          sequence: index + 1,
          total: @incident.total_messages
        }
      }
    )
  end
  
  def create_and_broadcast_suggestion(suggestion_data)
    # Avoid duplicate suggestions
    existing = @incident.suggestions.where(
      category: suggestion_data['category'],
      title: suggestion_data['title']
    ).first
    
    return if existing
    
    suggestion = @incident.suggestions.create!(
      category: suggestion_data['category'],
      title: suggestion_data['title'],
      description: suggestion_data['description'],
      status: :pending
    )
    
    # Broadcast new suggestion via Action Cable (frontend expects ai_insight format)
    ActionCable.server.broadcast(
      "incident_#{@incident.id}_suggestions",
      {
        type: 'ai_insight',
        data: {
          insight: {
            title: suggestion.title,
            content: suggestion.description,
            type: suggestion.category,
            confidence: 0.9 # Default confidence from LLM
          },
          timestamp: Time.current.to_i,
          related_to: suggestion.id
        }
      }
    )
    
    Rails.logger.info "Created suggestion: #{suggestion.category} - #{suggestion.title}"
  end
  
  def broadcast_completion
    ActionCable.server.broadcast(
      "incident_#{@incident.id}_suggestions",
      {
        type: 'replay_complete',
        message: 'Incident replay completed successfully'
      }
    )
  end
end
