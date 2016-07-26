class Activity < ApplicationRecord
    self.primary_key = "id"
    belongs_to :charActivity

    # Persisted properties don't need accessors defined?
    #attr_accessor :period
    #attr_accessor :prefix
    #attr_accessor :activityHash
    #attr_accessor :result
    #attr_accessor :team
    #attr_accessor :kd
    # Extra transient properties
    attr_accessor :activityIcon
    attr_accessor :activityName
    attr_accessor :sameTeam
    
    def as_json(options = { })
        # just in case someone says as_json(nil) and bypasses
        # our default...
        super((options || { }).merge({
            :methods => [:activityIcon, :activityName, :sameTeam]
        }))
    end

end
