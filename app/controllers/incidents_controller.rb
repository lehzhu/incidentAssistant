class IncidentsController < ApplicationController
  before_action :set_incident, only: [:show, :start_replay]
  
  def index
    @incidents = Incident.all.order(created_at: :desc)
  end
  
  def show
    @suggestions = @incident.suggestions.recent.limit(50)
    @recent_messages = @incident.transcript_messages.ordered.limit(20)
  end
  
  def start_replay
    if @incident.active?
      IncidentReplayJob.perform_later(@incident.id)
      redirect_to @incident, notice: 'Incident replay started! Watch for AI suggestions.'
    else
      redirect_to @incident, alert: 'Incident has already been processed.'
    end
  end
  
  private
  
  def set_incident
    @incident = Incident.find(params[:id])
  end
end
