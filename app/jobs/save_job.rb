class SaveJob < ApplicationController
    include SuckerPunch::Job
    workers 4

    def perform(toSave)
        ActiveRecord::Base.connection_pool.with_connection do
            if toSave.new_record? || toSave.changed?
                toSave.save!
                @@log.info("saved #{toSave.class}")
            else
                toSave.touch
                @@log.info("touched #{toSave.class}")
            end
        end
    end

end