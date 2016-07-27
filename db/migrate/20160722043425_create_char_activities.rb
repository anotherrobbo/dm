class CreateCharActivities < ActiveRecord::Migration[5.0]
  def change
    create_table :char_activities, id: false do |t|
      t.integer :id, null: false, index: { unique: true }, limit: 8
      t.timestamps null: false
    end
  end
end
