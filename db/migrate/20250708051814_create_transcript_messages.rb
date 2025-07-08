class CreateTranscriptMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :transcript_messages do |t|
      t.references :incident, null: false, foreign_key: true
      t.string :speaker
      t.text :content
      t.integer :sequence_number

      t.timestamps
    end
  end
end
