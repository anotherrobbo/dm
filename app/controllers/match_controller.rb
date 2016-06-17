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
        g1 = Rails.cache.fetch(params[:systemCode] + "|" + params[:id], expires_in: 15.minutes) do
            getGames(params[:systemCode], params[:id], getChars(params[:systemCode], params[:id]))
        end
        g2 = Rails.cache.fetch(params[:systemCode] + "|" + params[:id2], expires_in: 12.hours) do
            getGames(params[:systemCode], params[:id2], getChars(params[:systemCode], params[:id2]))
        end
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
                defs = false#@activityIcons.empty?
                #@@log.info(defs)
                data = jsonCall(@@bungieURL + "/Platform/Destiny/Stats/ActivityHistory/#{systemCode}/#{id}/#{char.id}/?definitions=#{defs}&mode=None&page=#{page}&count=#{count}")
                # Break if we've reached a page with no data
                if data["Response"]["data"]["activities"] == nil
                    break
                end
                data["Response"]["data"]["activities"].each do |act|
                    a = Activity.new
                    #@@log.info(act)
                    a.id = act["activityDetails"]["instanceId"]
                    a.period = act["period"]
                    a.prefix = act["activityDetails"]["activityTypeHashOverride"] > 0 ? "activityType" : "activity"
                    a.activityHash = act["activityDetails"]["activityTypeHashOverride"] > 0 ? act["activityDetails"]["activityTypeHashOverride"] : act["activityDetails"]["referenceId"]
                    a.result = act["values"]["standing"] != nil ? act["values"]["standing"]["basic"]["displayValue"][0] : nil
                    a.team = act["values"]["team"] != nil ? act["values"]["team"]["basic"]["displayValue"][0] : nil
                    a.kd = act["values"]["killsDeathsRatio"] != nil ? act["values"]["killsDeathsRatio"]["basic"]["displayValue"] : nil
                    games[a.id] = a
                end
                #if data["Response"]["definitions"] != nil
                    #@@log.info("Loading Defs")
                    #loadIcons(data["Response"]["definitions"]["activities"], "activity")
                    #loadIcons(data["Response"]["definitions"]["activityTypes"], "activityType")
                #end
                page += 1
            end
        end
        return games
    end
    
    #private def loadIcons(activityTypes, prefix)
    #    activityTypes.each do |at|
    #        #@@log.info(at)
    #        #@@log.info(at[1])
    #        @activityIcons[at[1]["#{prefix}Hash"]] = @@bungieURL + at[1]["icon"]
    #        @activityNames[at[1]["#{prefix}Hash"]] = at[1]["#{prefix}Name"]
    #    end
    #end
    
    private def getMatches(g1, g2)
        matches = Array.new
        g1.each do |key, g|
            if g2.has_key?(key) 
                #@@log.info(g["values"]["standing"])
                a = ActivityDetail.new
                a.id = g.id
                a.time = DateTime.parse(g.period)
                a.prefix = g.prefix
                a.activityHash = g.activityHash
                a.activityIcon = getActivityIcon(a.prefix, a.activityHash)
                a.activityName = getActivityName(a.prefix, a.activityHash)
                a.result = g.result
                a.team = g.team
                a.kd = g.kd
                a.sameTeam = g.team == nil || g.team == g2[key].team
                matches.push(a)
            end
        end
        return matches
    end
    
    private def getActivityIcon(prefix, actHash)
        return @@bungieURL + getActivityDef(prefix, actHash)["icon"]
    end
    
    private def getActivityName(prefix, actHash)
        return getActivityDef(prefix, actHash)["#{prefix}Name"]
    end
    
    private def getActivityDef(prefix, actHash)
        return Rails.cache.fetch("#{prefix}|#{actHash}") do
            @@log.info("Loading #{prefix}/#{actHash}")
            data = jsonCall(@@bungieURL + "/Platform/Destiny/Manifest/#{prefix}/#{actHash}/")
            data["Response"]["data"][prefix]
        end
    end

end
