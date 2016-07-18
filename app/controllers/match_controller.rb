class MatchController < PlayerController

    def matchPlayers
        system = params[:system]
        @model = getPlayer(system, params[:name])
        @model2 = getPlayer(system, params[:name2])
    end
    
    def matchGames
        # @@log.info("Cache location: " + Rails.cache.cache_path)
        c1 = getChars(getSummaryData(params[:systemCode], params[:id]))
        c2 = getChars(getSummaryData(params[:systemCode], params[:id2]))
        # TODO shortcut if both ids are the same
        proc = LoadProcess.new
        proc.id = SecureRandom.uuid
        proc.total = c1.length + c2.length
        proc.progress = 0
        Rails.cache.write(proc.id, proc, expires_in: 5.minutes)

        # Kick off a new job to do the processing
        MatchJob.perform_async(proc.id, params[:systemCode], params[:id], params[:id2], c1, c2)

        render json: proc
    end
    
    def pollProcess
        proc = Rails.cache.fetch(params[:id])
        render json: proc
    end

end
