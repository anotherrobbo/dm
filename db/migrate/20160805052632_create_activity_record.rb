class CreateActivityRecord < ActiveRecord::Migration[5.0]
  def change
    create_table :activity_records, id: false do |t|
      t.integer :id, null: false, index: { unique: true }, limit: 8
      t.references :player_record, index: true, foreign_key: {to_table: :player_records}, type: :integer, limit: 8, null: false
      t.text :activities
      t.timestamps null: false
    end
  end
end
