class CreateIncidents < ActiveRecord::Migration[7.2]
  def change
    create_table :incidents do |t|
      t.string :title
      t.integer :status
      t.text :description

      t.timestamps
    end
  end
end
