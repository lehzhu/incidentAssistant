class Incident < ApplicationRecord
  has_many :transcript_messages, dependent: :destroy
  has_many :suggestions, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :flags, dependent: :destroy
  
  enum status: { active: 0, resolved: 1 }
  
  validates :title, presence: true
  
  def total_messages
    transcript_messages.count
  end
  
  def processing_interval_seconds
    return 0 if total_messages.zero?
    60.0 / total_messages  # 1 minute total for 10x speed
  end
end
