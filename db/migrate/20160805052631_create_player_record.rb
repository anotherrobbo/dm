class CreatePlayerRecord < ActiveRecord::Migration[5.0]
  def change
    create_table :player_records, id: false do |t|
        t.integer :id, null: false, index: { unique: true }, limit: 8
        t.integer :systemCode, null: false
        t.string :name, null: false
        t.string :system, null: false
        t.integer :overviewCount, null: false, default: 0, limit: 8
        t.integer :matchesCount, null: false, default: 0, limit: 8
        t.timestamps null: false
    end
  end
end
