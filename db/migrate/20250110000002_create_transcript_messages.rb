class CreateTranscriptMessages < ActiveRecord::Migration[6.1]
  def change
    create_table :transcript_messages do |t|
      t.references :incident, null: false, foreign_key: true
      t.string :speaker, null: false
      t.text :content, null: false
      t.integer :sequence_number, null: false
      t.datetime :simulated_timestamp
      t.boolean :processed, default: false
      
      t.timestamps
    end
    
    add_index :transcript_messages, [:incident_id, :sequence_number]
    add_index :transcript_messages, :processed
  end
end 