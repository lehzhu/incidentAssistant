class SuggestionsController < ApplicationController
  def update
    @suggestion = Suggestion.find(params[:id])
    
    if @suggestion.update(suggestion_params)
      render json: { status: 'success', suggestion: @suggestion }
    else
      render json: { status: 'error', errors: @suggestion.errors }
    end
  end
  
  private
  
  def suggestion_params
    params.require(:suggestion).permit(:status)
  end
end
