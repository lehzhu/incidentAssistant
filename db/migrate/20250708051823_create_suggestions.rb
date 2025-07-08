class CreateSuggestions < ActiveRecord::Migration[7.2]
  def change
    create_table :suggestions do |t|
      t.references :incident, null: false, foreign_key: true
      t.string :category
      t.string :title
      t.text :description
      t.integer :status

      t.timestamps
    end
  end
end
