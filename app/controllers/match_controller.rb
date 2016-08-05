class MatchController < PlayerController

    def matchPlayers
        system = params[:system]
        @model = getPlayer(system, params[:name])
        @model2 = getPlayer(system, params[:name2])
    end
    
    def matchGames
        # @@log.info("Cache location: " + Rails.cache.cache_path)
        system = params[:system]
        pr1 = getPlayerRecord(system, params[:name])
        pr2 = getPlayerRecord(system, params[:name2])
        c1 = getChars(getSummaryData(pr1.systemCode, pr1.id))
        c2 = getChars(getSummaryData(pr2.systemCode, pr2.id))
        proc = LoadProcess.new
        proc.id = SecureRandom.uuid
        proc.total = c1.length + c2.length
        proc.progress = 0
        Rails.cache.write(proc.id, proc, expires_in: 5.minutes)

        # Kick off a new job to do the processing
        MatchJob.perform_async(proc.id, params[:systemCode], params[:id], params[:id2], c1, c2)

        @name1 = pr1.name
        @name2 = pr2.name
        @model = proc
    end
    
    def pollProcess
        proc = Rails.cache.fetch(params[:id])
        render json: proc
    end

end
