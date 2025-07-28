class TasksController < ApplicationController
  before_action :set_incident
  skip_before_action :verify_authenticity_token, only: [:create]

  def create
    @task = @incident.tasks.build(task_params)
    
    if @task.save
      Rails.logger.info "[TASK] Created task for incident #{@incident.id}: #{@task.description}"
      render json: { 
        success: true, 
        task: @task.as_json(only: [:id, :assignee, :description, :status, :created_at])
      }
    else
      render json: { success: false, errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_incident
    @incident = Incident.find(params[:incident_id])
  end

  def task_params
    params.require(:task).permit(:assignee, :description).merge(status: 'open')
  end
end
