class MatchController < PlayerController
    
    def matchGames
        # @@log.info("Cache location: " + Rails.cache.cache_path)
        proc = LoadProcess.new
        proc.id = SecureRandom.uuid
        proc.total = 0
        proc.progress = 0
        
        system = params[:system]
        pr1 = getPlayerRecord(system, params[:name])
        pr2 = getPlayerRecord(system, params[:name2])
        if pr1 != nil and pr2 != nil
            c1 = getChars(getSummaryData(pr1.systemCode, pr1.id))
            c2 = getChars(getSummaryData(pr2.systemCode, pr2.id))
            proc.total = c1.length + c2.length
        elsif pr1 == nil
            proc.error = 'Unable to find user ' + params[:name]
        elsif pr2 == nil
           proc.error = 'Unable to find user ' + params[:name2]
        end
        
        Rails.cache.write(proc.id, proc, expires_in: 5.minutes)
        
        if proc.error == nil
            # Kick off a new job to do the processing
            MatchJob.perform_async(proc.id, pr1.systemCode, pr1, pr2, c1, c2)
        end

        @name1 = pr1 != nil ? pr1.name : params[:name]
        @name2 = pr2 != nil ? pr2.name : params[:name2]
        @model = proc
        @@log.info("Returning: #{@model}")
    end
    
    def pollProcess
        proc = Rails.cache.fetch(params[:id])
        render json: proc
    end

end
