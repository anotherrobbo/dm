class AdminController < ApplicationController
    
    def cacheStats
        if Rails.cache.respond_to?(:stats)
            render json: Rails.cache.stats
        else
            render json: 'stats not available for this cache'
        end
    end
    
    def playerStats
        render json: PlayerRecord.order(overviewCount: :desc, matchesCount: :desc)
        #render json: ActivityRecord.order(id: :desc)
    end

end
