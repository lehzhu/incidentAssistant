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
      
      # Generate AI insights for certain messages
      if should_generate_insight?(message, index)
        insight = generate_ai_insight(message, messages[0..index])
        
        ActionCable.server.broadcast(
          "incident_#{incident_id}_suggestions",
          {
            type: 'ai_insight',
            data: {
              insight: insight,
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
  
  def should_generate_insight?(message, index)
    # Generate insights for key moments
    text = message['text'].downcase
    
    # Key triggers for insights
    triggers = [
      'error rate', 'spiked', 'affected', 'severity', 'sev-1', 'sev-2',
      'rollback', 'deploy', 'database', 'postgres', 'pegged', 'cpu',
      'root cause', 'postmortem', 'action item', 'follow up'
    ]
    
    triggers.any? { |trigger| text.include?(trigger) } || 
    (index + 1) % 15 == 0 # Every 15th message
  end
  
  def generate_ai_insight(current_message, context_messages)
    text = current_message['text'].downcase
    
    case 
    when text.include?('error rate') || text.include?('spiked')
      {
        type: 'issue_detection',
        title: 'Service Degradation Detected',
        content: 'High error rate indicates potential service degradation. Consider checking affected services and escalating severity if needed.',
        action_items: ['Check affected services', 'Consider severity escalation'],
        confidence: 0.9
      }
    when text.include?('affected') && text.include?('service')
      {
        type: 'service_impact',
        title: 'Multiple Services Affected',
        content: 'Multiple services appear to be impacted. This suggests a shared dependency issue rather than service-specific problems.',
        action_items: ['Document affected services in incident record', 'Investigate shared dependencies'],
        confidence: 0.85
      }
    when text.include?('sev-1') || text.include?('sev-2')
      {
        type: 'severity_recommendation',
        title: 'Severity Assessment',
        content: 'Team is discussing severity classification. Consider impact scope and customer effect when determining appropriate severity level.',
        action_items: ['Update incident severity', 'Notify stakeholders of severity change'],
        confidence: 0.8
      }
    when text.include?('postgres') || text.include?('database')
      {
        type: 'root_cause_analysis',
        title: 'Database Performance Issue',
        content: 'Database performance degradation identified. This is likely a key contributing factor to the observed service issues.',
        action_items: ['Investigate database queries', 'Check recent database changes'],
        confidence: 0.95
      }
    when text.include?('deploy') || text.include?('rollback')
      {
        type: 'deployment_correlation',
        title: 'Deployment Correlation',
        content: 'Timeline correlation with recent deployment suggests this may be the root cause. Consider rollback as remediation.',
        action_items: ['Verify deployment timeline', 'Prepare rollback plan'],
        confidence: 0.9
      }
    when text.include?('rollback') && (text.include?('completed') || text.include?('resolved'))
      {
        type: 'resolution_confirmed',
        title: 'Resolution Confirmed',
        content: 'Rollback appears to have resolved the issue. Monitor for full recovery and document learnings.',
        action_items: ['Monitor service recovery', 'Schedule postmortem'],
        confidence: 0.95
      }
    when text.include?('postmortem') || text.include?('follow up') || text.include?('action item')
      {
        type: 'process_improvement',
        title: 'Process Improvement Opportunity',
        content: 'Team has identified process improvement opportunities. Ensure these are captured and tracked.',
        action_items: ['Document improvement opportunities', 'Create follow-up tickets'],
        confidence: 0.8
      }
    else
      # Generic insight based on message position
      position = context_messages.length
      case
      when position < 10
        {
          type: 'early_detection',
          title: 'Incident Response Initiated',
          content: 'Team is in early detection phase. Focus on impact assessment and initial triage.',
          action_items: ['Assess service impact', 'Gather initial symptoms'],
          confidence: 0.7
        }
      when position < 30
        {
          type: 'investigation',
          title: 'Active Investigation',
          content: 'Team is actively investigating the issue. Continue systematic troubleshooting approach.',
          action_items: ['Continue systematic investigation', 'Rule out common causes'],
          confidence: 0.7
        }
      else
        {
          type: 'resolution_phase',
          title: 'Resolution Phase',
          content: 'Team appears to be in resolution or learning phase. Focus on documentation and follow-up.',
          action_items: ['Document resolution steps', 'Plan postmortem'],
          confidence: 0.7
        }
      end
    end
  end
end
