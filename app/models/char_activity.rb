class CharActivity < ApplicationRecord
    self.primary_key = "id"
    has_many :activities
end
