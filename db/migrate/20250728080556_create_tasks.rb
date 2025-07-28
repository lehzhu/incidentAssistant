class CreateTasks < ActiveRecord::Migration[7.2]
  def change
    create_table :tasks do |t|
      t.references :incident, null: false, foreign_key: true
      t.string :assignee
      t.text :description
      t.string :status

      t.timestamps
    end
  end
end
