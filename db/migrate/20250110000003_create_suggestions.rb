class CreateSuggestions < ActiveRecord::Migration[6.1]
  def change
    create_table :suggestions do |t|
      t.references :incident, null: false, foreign_key: true
      t.string :category, null: false
      t.string :title, null: false
      t.text :description, null: false
      t.string :status, default: 'pending'
      t.text :context
      t.integer :confidence_score
      
      t.timestamps
    end
    
    add_index :suggestions, [:incident_id, :status]
    add_index :suggestions, :category
  end
end 