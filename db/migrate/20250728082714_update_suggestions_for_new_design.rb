class UpdateSuggestionsForNewDesign < ActiveRecord::Migration[7.2]
  def change
    remove_column :suggestions, :category, :string
    add_column :suggestions, :speaker, :string
    add_column :suggestions, :is_action_item, :boolean, default: false
    
    # Add indexes for performance
    add_index :suggestions, :speaker
    add_index :suggestions, :is_action_item
  end
end
