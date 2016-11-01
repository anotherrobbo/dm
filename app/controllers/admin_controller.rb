class AdminController < ApplicationController

    def index
    end
    
    def cacheStats
        if Rails.cache.respond_to?(:stats)
            render json: Rails.cache.stats
        else
            render json: 'stats not available for this cache'
        end
    end
    
    def playerStats
        @model = PlayerRecord.order(overviewCount: :desc, matchesCount: :desc)
    end
    
    def bulkLoad
        proc = BulkLoadProcess.new
        proc.id = SecureRandom.uuid
        proc.running = true;
        Rails.cache.write(proc.id, proc, expires_in: 5.minutes)
        BulkLoadJob.perform_async(proc.id)
        @model = proc
    end

end
