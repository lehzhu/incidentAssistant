class Suggestion < ApplicationRecord
  belongs_to :incident
  
  enum status: { pending: 0, accepted: 1, dismissed: 2 }
  
  validates :title, :description, presence: true
  
  # Sorting scopes
  scope :chronological_asc, -> { order(created_at: :asc) }
  scope :chronological_desc, -> { order(created_at: :desc) }
  scope :by_importance_desc, -> { order(importance_score: :desc, created_at: :desc) }
  scope :by_importance_asc, -> { order(importance_score: :asc, created_at: :desc) }
  scope :by_speaker, -> { order(speaker: :asc, created_at: :desc) }
  
  # Filtering scopes
  scope :action_items_only, -> { where(is_action_item: true) }
  scope :critical, -> { where('importance_score >= ?', 90) }
  
  def critical?
    importance_score.to_i >= 90
  end
  
  def high_priority?
    importance_score.to_i >= 70
  end
  
  def important?
    high_priority?
  end
end
