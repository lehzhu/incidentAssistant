class FlagsController < ApplicationController
  before_action :set_incident
  skip_before_action :verify_authenticity_token, only: [:create]

  def create
    @flag = @incident.flags.build(flag_params)
    
    if @flag.save
      Rails.logger.info "[FLAG] Created flag for incident #{@incident.id}: #{@flag.flag_type} - #{@flag.description}"
      render json: { 
        success: true, 
        flag: @flag.as_json(only: [:id, :flag_type, :description, :reporter, :created_at])
      }
    else
      render json: { success: false, errors: @flag.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_incident
    @incident = Incident.find(params[:incident_id])
  end

  def flag_params
    params.require(:flag).permit(:flag_type, :description, :reporter)
  end
end
