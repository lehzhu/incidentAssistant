class CreateIncidents < ActiveRecord::Migration[6.1]
  def change
    create_table :incidents do |t|
      t.string :title, null: false
      t.text :description
      t.string :status, default: 'active'
      t.text :transcript_data
      t.integer :total_messages, default: 0
      t.integer :processed_messages, default: 0
      t.boolean :replay_completed, default: false
      
      t.timestamps
    end
    
    add_index :incidents, :status
    add_index :incidents, :replay_completed
  end
end 