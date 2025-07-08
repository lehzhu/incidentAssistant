class SuggestionsChannel < ApplicationCable::Channel
  def subscribed
    incident_id = params[:incident_id]
    stream_from "incident_#{incident_id}_suggestions"
    
    Rails.logger.info "Client subscribed to incident #{incident_id} suggestions"
  end
  
  def unsubscribed
    Rails.logger.info "Client unsubscribed from suggestions channel"
  end
end
