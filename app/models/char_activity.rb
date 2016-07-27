class CharActivity < ApplicationRecord
    self.primary_key = "id"
    serialize :activities, Hash
end
