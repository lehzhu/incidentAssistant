class TranscriptMessage < ApplicationRecord
  belongs_to :incident
  
  validates :speaker, :content, :sequence_number, presence: true
  
  scope :ordered, -> { order(:sequence_number) }
  scope :up_to_sequence, ->(seq) { where('sequence_number <= ?', seq) }
end
