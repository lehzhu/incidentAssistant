class AddImportanceScoreToSuggestions < ActiveRecord::Migration[7.2]
  def change
    add_column :suggestions, :importance_score, :integer, default: 50
    add_index :suggestions, :importance_score
  end
end
