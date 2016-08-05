class PlayerRecord < ApplicationRecord
    self.primary_key = "id"
    has_many :activityRecords
end
