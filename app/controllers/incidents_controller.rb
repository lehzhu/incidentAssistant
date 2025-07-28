class IncidentsController < ApplicationController
  before_action :set_incident, only: [:show, :start_replay, :export]
  skip_before_action :verify_authenticity_token, only: [:start_replay]
  
  def index
    @incidents = Incident.all.order(created_at: :desc)
  end
  
  def show
    @suggestions = @incident.suggestions.chronological_desc.limit(50)
    @recent_messages = @incident.transcript_messages.ordered.limit(20)
    @progress = 0  # Initialize progress for now
  end
  
  def create
    @incident = Incident.new(incident_params)
    
    if @incident.save
      # Process transcript data if provided
      if params[:incident][:transcript_data].present?
        process_transcript_data(@incident, params[:incident][:transcript_data])
      end
      
      render json: { id: @incident.id }
    else
      render json: { errors: @incident.errors.full_messages }
    end
  end
  
  def start_replay
    # Check if a job is already running for this incident
    cache_key = "incident_replay_running_#{@incident.id}"
    
    if Rails.cache.read(cache_key)
      render json: { error: 'Transcript replay is already running for this incident.' }
    else
      # For demo purposes, reset the incident if it's resolved
      if @incident.resolved?
        Rails.logger.info "[REPLAY] Resetting resolved incident #{@incident.id} for demo replay"
        @incident.update!(status: :active, replay_completed: false)
        @incident.suggestions.destroy_all # Clear previous suggestions for clean replay
      end
      
      # Set a cache flag for 5 minutes (longer than expected job duration)
      Rails.cache.write(cache_key, true, expires_in: 5.minutes)
      
      Rails.logger.info "[REPLAY] Starting IncidentReplayJob for incident #{@incident.id}"
      IncidentReplayJob.perform_async(@incident.id)
      
      render json: { message: 'Transcript replay started! Watch for AI insights.' }
    end
  end

  def export
    export_data = {
      incident: {
        title: @incident.title,
        description: @incident.description,
        created_at: @incident.created_at,
        status: @incident.status
      },
      suggestions: @incident.suggestions.as_json(only: [:category, :title, :description, :importance_score]),
      tasks: @incident.tasks.as_json(only: [:assignee, :description, :status]),
      flags: @incident.flags.as_json(only: [:flag_type, :description, :reporter])
    }

    send_data export_data.to_json, filename: "incident_#{@incident.id}_export.json", type: :json
  end
  
  private
  
  def set_incident
    @incident = Incident.find(params[:id])
  end
  
  def incident_params
    params.require(:incident).permit(:title, :description)
  end
  
  def process_transcript_data(incident, transcript_json)
    data = JSON.parse(transcript_json)
    messages = data['meeting_transcript'] || data # Handle both formats

    messages.each_with_index do |message_data, index|
      incident.transcript_messages.create!(
        speaker: message_data['speaker'],
        content: message_data['text'] || message_data['content'], # Handle both 'text' and 'content' keys
        sequence_number: index + 1
      )
    end
    # update total_messages on the incident record
    incident.update(total_messages: incident.transcript_messages.count)
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse transcript JSON for incident #{incident.id}: #{e.message}"
  end
end
