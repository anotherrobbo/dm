class CreateActivities < ActiveRecord::Migration[5.0]
  def change
    create_table :activities, id: false do |t|
      t.integer :id, null: false, index: { unique: true }, limit: 8
      t.datetime :period
      t.string :prefix
      t.string :activityHash
      t.integer :result
      t.string :team
      t.string :kd
      t.references :char_activity, index: true, foreign_key: {to_table: :char_activities}, type: :integer, limit: 8, null: false
      t.timestamps null: false
    end
  end
end
