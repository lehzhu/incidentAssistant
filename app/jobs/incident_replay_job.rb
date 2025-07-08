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
      
      # CRITICAL: Only use messages up to current point (streaming simulation)
      context_messages = @incident.transcript_messages
                                  .up_to_sequence(current_message.sequence_number)
                                  .ordered
                                  .last(8)  # Use last 8 messages as context window
      
      # Generate AI suggestions based on context
      suggestions = @ai_analyzer.analyze_transcript_chunk(context_messages)
      
      # Create and broadcast suggestions
      suggestions.each do |suggestion_data|
        create_and_broadcast_suggestion(suggestion_data)
      end
      
      # Wait before processing next message (simulate real-time)
      sleep(@incident.processing_interval_seconds)
    end
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
    
    # Broadcast new suggestion via Action Cable
    ActionCable.server.broadcast(
      "incident_#{@incident.id}_suggestions",
      {
        type: 'new_suggestion',
        suggestion: suggestion.as_json
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
