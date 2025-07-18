class IncidentsController < ApplicationController
  before_action :set_incident, only: [:show, :start_replay]
  skip_before_action :verify_authenticity_token, only: [:start_replay]
  
  def index
    @incidents = Incident.all.order(created_at: :desc)
  end
  
  def show
    @suggestions = @incident.suggestions.recent.limit(50)
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
    if @incident.active?
      # Check if a job is already running for this incident
      cache_key = "transcript_job_running_#{@incident.id}"
      
      if Rails.cache.read(cache_key)
        render json: { error: 'Transcript replay is already running for this incident.' }
      else
        # Set a cache flag for 5 minutes (longer than expected job duration)
        Rails.cache.write(cache_key, true, expires_in: 5.minutes)
        StreamTranscriptJob.perform_async(@incident.id)
        render json: { message: 'Transcript replay started! Watch for AI insights.' }
      end
    else
      render json: { error: 'Incident has already been processed.' }
    end
  end
  
  private
  
  def set_incident
    @incident = Incident.find(params[:id])
  end
  
  def incident_params
    params.require(:incident).permit(:title, :description)
  end
  
  def process_transcript_data(incident, transcript_json)
    begin
      transcript_data = JSON.parse(transcript_json)
      
      transcript_data.each_with_index do |message, index|
        incident.transcript_messages.create!(
          speaker: message['speaker'],
          content: message['content'],
          sequence_number: index + 1
        )
      end
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse transcript JSON: #{e.message}"
    end
  end
end
