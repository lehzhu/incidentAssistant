class Suggestion < ApplicationRecord
  belongs_to :incident
  
  CATEGORIES = %w[action_item timeline_event root_cause missing_info].freeze
  
  enum status: { pending: 0, accepted: 1, dismissed: 2 }
  
  validates :category, inclusion: { in: CATEGORIES }
  validates :title, :description, presence: true
  
  scope :recent, -> { order(created_at: :desc) }
  scope :by_category, ->(cat) { where(category: cat) }
end
