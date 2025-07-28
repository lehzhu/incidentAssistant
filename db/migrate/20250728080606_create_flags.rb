class CreateFlags < ActiveRecord::Migration[7.2]
  def change
    create_table :flags do |t|
      t.references :incident, null: false, foreign_key: true
      t.string :flag_type
      t.text :description
      t.string :reporter

      t.timestamps
    end
  end
end
