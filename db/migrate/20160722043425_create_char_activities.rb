class CreateCharActivities < ActiveRecord::Migration[5.0]
  def change
    create_table :char_activities, id: false do |t|
      t.integer :id, null: false, index: true, limit: 20
      t.timestamps null: false
    end
  end
end
