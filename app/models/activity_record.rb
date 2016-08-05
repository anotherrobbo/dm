class ActivityRecord < ApplicationRecord
    self.primary_key = "id"
    belongs_to :playerRecord
    serialize :activities, Hash
end
