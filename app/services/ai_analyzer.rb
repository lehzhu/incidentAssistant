class AiAnalyzer
  def initialize
    @client = GoogleGenerativeAI::Client.new(
      api_key: Rails.application.credentials.google_api_key
    )
  end
  
  def analyze_transcript_chunk(messages)
    return [] if messages.empty? || messages.count < 3
    
    prompt = build_analysis_prompt(messages)
    
    response = @client.generate_content(
      model: 'gemini-1.5-flash',
      contents: prompt,
      generation_config: {
        response_mime_type: 'application/json',
        temperature: 0.1
      }
    )
    
    parse_ai_response(response.text)
  rescue => e
    Rails.logger.error "AI Analysis failed: #{e.message}"
    []
  end
  
  private
  
  def build_analysis_prompt(messages)
    context = format_messages_for_ai(messages)
    
    <<~PROMPT
      You are analyzing an incident response conversation. Extract actionable insights from this discussion.
      
      Conversation context:
      #{context}
      
      Extract suggestions in these categories:
      
      1. action_item - Tasks the team needs to do later:
         • Documentation updates
         • Process improvements  
         • Follow-up investigations
         • Code fixes or monitoring changes
      
      2. timeline_event - Important status changes to record:
         • Problem resolution or mitigation
         • Key discoveries or breakthroughs  
         • Status escalations or changes
         • Recovery milestones
      
      3. root_cause - Theories about what caused the issue:
         • Recent deployments or code changes
         • Infrastructure or configuration issues
         • Third-party service problems
         • Performance bottlenecks
      
      4. missing_info - Important details that should be documented:
         • Affected services or customer segments
         • Impact severity or metrics
         • Timeline information
         • Dependencies or relationships
      
      Return a JSON array of suggestions:
      [
        {
          "category": "action_item",
          "title": "Brief, actionable title (max 60 chars)",
          "description": "Clear explanation of why this matters (max 150 chars)"
        }
      ]
      
      Guidelines:
      - Only include clear, actionable items that were explicitly mentioned or strongly implied
      - Avoid duplicating suggestions for the same topic
      - Focus on items that incident responders would actually need to track
      - Return empty array [] if no clear suggestions emerge
    PROMPT
  end
  
  def format_messages_for_ai(messages)
    messages.map { |msg| "#{msg.speaker}: #{msg.content}" }.join("\n")
  end
  
  def parse_ai_response(response_text)
    suggestions = JSON.parse(response_text)
    
    return [] unless suggestions.is_a?(Array)
    
    suggestions.filter_map do |suggestion|
      next unless valid_suggestion?(suggestion)
      suggestion
    end
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse AI response: #{e.message}"
    []
  end
  
  def valid_suggestion?(suggestion)
    return false unless suggestion.is_a?(Hash)
    
    required_keys = %w[category title description]
    return false unless required_keys.all? { |key| suggestion[key].present? }
    
    return false unless Suggestion::CATEGORIES.include?(suggestion['category'])
    
    true
  end
end
