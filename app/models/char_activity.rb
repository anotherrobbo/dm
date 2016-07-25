class CharActivity < ActiveRecord::Base
    self.primary_key = "id"
    has_many :activities
end
