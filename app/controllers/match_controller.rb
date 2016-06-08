class MatchController < PlayerController

    def matchPlayers
        system = params[:system]
        @model = getPlayer(system, params[:name])
        @model2 = getPlayer(system, params[:name2])
        #g1 = getGames(@model.systemCode, @model.id, @model.chars)
        #g2 = getGames(@model2.systemCode, @model2.id, @model2.chars)
        #@matches = getMatches(g1, g2)
        # Reverse sort by time
        #@matches.sort! { |a, b| b.time <=> a.time }
    end
    
    def matchGames
        @activityIcons = Hash.new
        @activityNames = Hash.new
        g1 = getGames(params[:systemCode], params[:id], getChars(params[:systemCode], params[:id]))
        g2 = getGames(params[:systemCode], params[:id2], getChars(params[:systemCode], params[:id2]))
        matches = getMatches(g1, g2)
        # Reverse sort by time
        matches.sort! { |a, b| b.time <=> a.time }
        render json: matches
    end
    
    private def getGames(systemCode, id, chars)
        count = 250
        games = Hash.new
        chars.each do |char|
            page = 0
            #@@log.info(char)
            while 1
                @@log.info("#{page} - #{char.id}")
                defs = @activityIcons.empty?
                #@@log.info(defs)
                data = jsonCall(@@bungieURL + "/Platform/Destiny/Stats/ActivityHistory/#{systemCode}/#{id}/#{char.id}/?definitions=#{defs}&mode=None&page=#{page}&count=#{count}")
                # Break if we've reached a page with no data
                if data["Response"]["data"]["activities"] == nil
                    break
                end
                data["Response"]["data"]["activities"].each do |act|
                    games[act["activityDetails"]["instanceId"]] = act
                end
                if data["Response"]["definitions"] != nil
                    #@@log.info("Loading Defs")
                    loadIcons(data["Response"]["definitions"]["activities"], "activity")
                    loadIcons(data["Response"]["definitions"]["activityTypes"], "activityType")
                end
                page += 1
            end
        end
        return games
    end
    
    private def loadIcons(activityTypes, prefix)
        activityTypes.each do |at|
            #@@log.info(at)
            #@@log.info(at[1])
            @activityIcons[at[1]["#{prefix}Hash"]] = @@bungieURL + at[1]["icon"]
            @activityNames[at[1]["#{prefix}Hash"]] = at[1]["#{prefix}Name"]
        end
    end
    
    private def getMatches(g1, g2)
        matches = Array.new
        g1.each do |key, g|
            if g2.has_key?(key) 
                #@@log.info(g["values"]["standing"])
                a = Activity.new
                a.id = key
                a.time = DateTime.parse(g["period"])
                a.activityHash = g["activityDetails"]["activityTypeHashOverride"] > 0 ? g["activityDetails"]["activityTypeHashOverride"] : g["activityDetails"]["referenceId"]
                a.activityIcon = @activityIcons[a.activityHash]
                a.activityName = @activityNames[a.activityHash]
                a.result = g["values"]["standing"] != nil ? g["values"]["standing"]["basic"]["displayValue"] : nil
                matches.push(a)
            end
        end
        return matches
    end

end
