class Suggestion < ApplicationRecord
  belongs_to :incident
  
  CATEGORIES = %w[action_item timeline_event root_cause missing_info].freeze
  
  enum status: { pending: 0, accepted: 1, dismissed: 2 }
  
  validates :category, inclusion: { in: CATEGORIES }
  validates :title, :description, presence: true
  
  scope :recent, -> { order(created_at: :desc) }
  scope :by_category, ->(cat) { where(category: cat) }
  scope :important, -> { where('importance_score >= ?', 70).order(importance_score: :desc) }
  scope :by_importance, -> { order(importance_score: :desc, created_at: :desc) }
  
  def category_display
    category.tr('_', ' ').split.map(&:capitalize).join(' ')
  end
  
  def important?
    importance_score >= 70
  end
end
