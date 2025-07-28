class AiAnalyzer
  def initialize
    api_key = Rails.application.credentials.google_api_key || ENV['GOOGLE_API_KEY']
    
    if api_key.present?
      @client = Gemini.new(
        credentials: {
          service: 'generative-language-api',
          api_key: api_key
        },
        options: {
          model: 'gemini-1.5-flash'
        }
      )
    else
      @client = nil
      Rails.logger.warn "Google API key not configured. AI analysis will be skipped."
    end
  end
  
  def analyze_transcript_chunk(messages)
    return [] if messages.empty? || messages.count < 3
    
    # Skip AI analysis if client is not configured
    unless @client
      Rails.logger.warn "Gemini client not configured, skipping AI analysis"
      return []
    end
    
    Rails.logger.info "[AI_ANALYZER] Making PRODUCTION LLM call to Google Gemini API"
    Rails.logger.info "[AI_ANALYZER] Analyzing #{messages.count} messages from sequence #{messages.first.sequence_number} to #{messages.last.sequence_number}"
    
    prompt = build_analysis_prompt(messages)
    
    # Format prompt correctly for gemini-rb gem
    content = {
      contents: [
        {
          parts: [
            {
              text: prompt
            }
          ]
        }
      ]
    }
    
    response = @client.generate_content(content)
    
    # Handle different possible response formats
    response_text = case response
    when Hash
      response.dig('candidates', 0, 'content', 'parts', 0, 'text') || 
      response.dig('text') ||
      response.to_s
    when String
      response
    else
      response.to_s
    end
    
    parse_ai_response(response_text)
  rescue => e
    Rails.logger.error "AI Analysis failed: #{e.message}"
    Rails.logger.error "Error details: #{e.backtrace.first(5).join('\n')}"
    Rails.logger.error "Full error: #{e.inspect}"
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
          "description": "Clear explanation of why this matters (max 150 chars)",
          "importance": 85  // Score 0-100, where 70+ is "important"
        }
      ]
      
      Importance scoring guidelines:
      - 90-100: Critical issues (data loss, security, major outages)
      - 70-89: Important (customer impact, performance issues, missing documentation)
      - 50-69: Moderate (process improvements, minor issues)
      - 0-49: Low priority (nice-to-have, minor optimizations)
      
      Guidelines:
      - Be HIGHLY SELECTIVE - only extract the most important and actionable items
      - Focus on items with real business impact or critical technical issues
      - Avoid generic or obvious suggestions (e.g., "update documentation" without specifics)
      - Limit to 2-3 suggestions per analysis chunk unless there are truly critical issues
      - Prioritize suggestions with importance score >= 70
      - Return empty array [] if no high-value suggestions emerge
    PROMPT
  end
  
  def format_messages_for_ai(messages)
    messages.map { |msg| "#{msg.speaker}: #{msg.content}" }.join("\n")
  end
  
  def parse_ai_response(response_text)
    # Remove markdown code blocks if present
    cleaned_text = response_text.strip
    if cleaned_text.start_with?('```json')
      cleaned_text = cleaned_text.gsub(/^```json\s*/, '').gsub(/```\s*$/, '')
    elsif cleaned_text.start_with?('```')
      cleaned_text = cleaned_text.gsub(/^```\s*/, '').gsub(/```\s*$/, '')
    end
    
    suggestions = JSON.parse(cleaned_text)
    
    return [] unless suggestions.is_a?(Array)
    
    suggestions.filter_map do |suggestion|
      next unless valid_suggestion?(suggestion)
      suggestion
    end
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse AI response: #{e.message}"
    Rails.logger.error "Response text was: #{response_text[0..200]}..."
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
