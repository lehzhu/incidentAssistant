class StreamTranscriptJob
  include Sidekiq::Worker

  def perform(incident_id)
    incident = Incident.find(incident_id)
    
    # Load transcript data
    transcript_path = Rails.root.join('transcript.json')
    transcript_data = JSON.parse(File.read(transcript_path))
    messages = transcript_data['meeting_transcript']
    
    # Calculate timing: stream over 60 seconds
    total_messages = messages.length
    interval = 60.0 / total_messages # seconds per message
    
    # Track insights to avoid duplicates
    @existing_insights = {}
    
    messages.each_with_index do |message, index|
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
      
      # Evaluate message for insights
      insight_action = evaluate_message_for_insight(message, messages[0..index], index)
      
      if insight_action
        ActionCable.server.broadcast(
          "incident_#{incident_id}_suggestions",
          {
            type: 'ai_insight',
            data: {
              insight: insight_action,
              timestamp: Time.current.to_i,
              related_to: index + 1
            }
          }
        )
      end
      
      # Sleep until next message
      sleep(interval)
    end
    
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
  end
  
  private
  
  def evaluate_message_for_insight(message, context_messages, index)
    text = message['text'].downcase
    speaker = message['speaker']
    
    # Check for various insight triggers
    case
    when text.include?('error rate') || text.include?('spiked')
      update_or_create_insight('Issue Detection', {
        content: 'High error rate detected - service degradation in progress. Immediate impact assessment needed.',
        action_items: ['Check affected services', 'Assess customer impact', 'Consider severity escalation'],
        confidence: 0.9,
        type: 'critical'
      })
      
    when text.include?('affected') && (text.include?('service') || text.include?('web') || text.include?('analytics'))
      update_or_create_insight('Service Impact Analysis', {
        content: 'Multiple services affected - suggests shared dependency or infrastructure issue.',
        action_items: ['Document all affected services', 'Identify common dependencies', 'Update incident scope'],
        confidence: 0.85,
        type: 'analysis'
      })
      
    when text.include?('sev-1') || text.include?('sev-2') || text.include?('severity')
      update_or_create_insight('Severity Assessment', {
        content: 'Team discussing incident severity. Proper classification affects response and communication.',
        action_items: ['Confirm severity level', 'Notify appropriate stakeholders', 'Activate escalation procedures'],
        confidence: 0.8,
        type: 'process'
      })
      
    when text.include?('postgres') || text.include?('database') || text.include?('cpu') || text.include?('pegged')
      update_or_create_insight('Root Cause Identified', {
        content: 'Database performance issues identified as likely root cause. Focus investigation here.',
        action_items: ['Analyze database queries', 'Check resource utilization', 'Review recent changes'],
        confidence: 0.95,
        type: 'technical'
      })
      
    when text.include?('deploy') && !text.include?('rollback')
      update_or_create_insight('Deployment Correlation', {
        content: 'Recent deployment timeline correlates with incident start. Investigate deployment changes.',
        action_items: ['Review deployment changes', 'Check deployment logs', 'Prepare rollback plan'],
        confidence: 0.88,
        type: 'technical'
      })
      
    when text.include?('rollback') && !text.include?('complete')
      update_or_create_insight('Rollback Decision', {
        content: 'Team deciding on rollback strategy. Quick decision needed to minimize impact.',
        action_items: ['Confirm rollback procedure', 'Identify rollback owner', 'Estimate rollback time'],
        confidence: 0.9,
        type: 'action'
      })
      
    when text.include?('rollback') && (text.include?('complete') || text.include?('resolve'))
      update_or_create_insight('Resolution Progress', {
        content: 'Rollback completed - monitoring for service recovery and confirming resolution.',
        action_items: ['Monitor service metrics', 'Confirm customer impact resolved', 'Prepare status update'],
        confidence: 0.93,
        type: 'resolution'
      })
      
    when text.include?('postmortem') || text.include?('follow up') || text.include?('action item')
      update_or_create_insight('Post-Incident Planning', {
        content: 'Team identifying follow-up actions and process improvements from this incident.',
        action_items: ['Schedule postmortem meeting', 'Document lessons learned', 'Create improvement tickets'],
        confidence: 0.85,
        type: 'learning'
      })
      
    when text.include?('customer') || text.include?('cs') || text.include?('reports')
      update_or_create_insight('Customer Impact', {
        content: 'Customer reports confirmed - external impact being tracked and communicated.',
        action_items: ['Update status page', 'Prepare customer communication', 'Track affected customers'],
        confidence: 0.9,
        type: 'communication'
      })
      
    # Generate contextual insights based on conversation flow
    when index == 5
      update_or_create_insight('Incident Triage', {
        content: 'Initial triage phase - team gathering information and assessing scope.',
        action_items: ['Confirm incident scope', 'Establish communication channels', 'Assign roles'],
        confidence: 0.7,
        type: 'process'
      })
      
    when index == 20
      update_or_create_insight('Investigation Phase', {
        content: 'Active investigation underway - systematic troubleshooting approach needed.',
        action_items: ['Continue systematic investigation', 'Document findings', 'Rule out common causes'],
        confidence: 0.75,
        type: 'process'
      })
    end
  end

  def update_or_create_insight(title, attributes)
    if @existing_insights[title]
      # Append and increment confidence slightly
      @existing_insights[title][:content] += " Additional context shows continued issues."
      @existing_insights[title][:confidence] += 0.05
      nil # No need to broadcast again, just update
    else
      # Create new insight
      @existing_insights[title] = attributes.merge({ title: title })
      @existing_insights[title] # Return new insight to broadcast
    end
  end
  
end
