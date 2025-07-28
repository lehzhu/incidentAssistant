class AddTranscriptReferenceToSuggestions < ActiveRecord::Migration[7.2]
  def change
    add_column :suggestions, :trigger_message_sequence, :integer
  end
end
