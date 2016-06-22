class MatchController < PlayerController

    def matchPlayers
        system = params[:system]
        @model = getPlayer(system, params[:name])
        @model2 = getPlayer(system, params[:name2])
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
    
    def matchDetails
        activityStats = getActivityStats(params[:id])
        render json: activityStats
    end
    
    private def getGames(systemCode, id, chars)
        count = 250
        games = Hash.new
        chars.each do |char|
            page = 0
            #@@log.info(char)
            while 1
                @@log.info("#{page} - #{char.id}")
                defs = false
                #@@log.info(defs)
                data = jsonCall(@@bungieURL + "/Platform/Destiny/Stats/ActivityHistory/#{systemCode}/#{id}/#{char.id}/?definitions=#{defs}&mode=None&page=#{page}&count=#{count}")
                # Break if we've reached a page with no data
                if data["Response"]["data"]["activities"] == nil
                    break
                end
                data["Response"]["data"]["activities"].each do |act|
                    useType = act["activityDetails"]["activityTypeHashOverride"] > 0 && act["activityDetails"]["mode"] != 4
                    a = Activity.new
                    #@@log.info(act)
                    a.id = act["activityDetails"]["instanceId"]
                    a.period = act["period"]
                    a.prefix = useType ? "activityType" : "activity"
                    a.activityHash = useType ? act["activityDetails"]["activityTypeHashOverride"] : act["activityDetails"]["referenceId"]
                    a.result = act["values"]["standing"] != nil ? act["values"]["standing"]["basic"]["displayValue"][0] : nil
                    a.team = act["values"]["team"] != nil ? act["values"]["team"]["basic"]["displayValue"][0] : nil
                    a.kd = act["values"]["killsDeathsRatio"] != nil ? act["values"]["killsDeathsRatio"]["basic"]["displayValue"] : nil
                    games[a.id] = a
                end
                page += 1
            end
        end
        return games
    end
    
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
    
    private def getActivityStats(id)
        activityStats = ActivityStats.new
        data = jsonCall(@@bungieURL + "/Platform/Destiny/Stats/PostGameCarnageReport/#{id}/")
        # Not all have teams
        if data["Response"]["data"]["teams"] == nil || data["Response"]["data"]["teams"].empty?
            activityStats.playerStats = getPlayerStats(data["Response"]["data"], nil);
        else
            activityStats.teamStats = getTeamStats(data["Response"]["data"]);
        end
        return activityStats
    end
    
    private def getTeamStats(data)
        teams = Array.new
        data["teams"].each do |teamEntry|
            t = TeamStats.new
            #@@log.info(act)
            t.id = teamEntry["teamId"]
            t.name = teamEntry["teamName"]
            t.result = teamEntry["standing"]["basic"]["displayValue"]
            t.score = teamEntry["score"]["basic"]["displayValue"]
            t.playerStats = getPlayerStats(data, t.id)
            teams.push(t)
        end
        return teams
    end
    
    private def getPlayerStats(data, teamId)
        @@log.info("Get player stats #{teamId}")
        players = Array.new
        data["entries"].each do |playerEntry|
            if teamId == nil || playerEntry["values"]["team"]["basic"]["value"] == teamId
                p = PlayerStats.new
                #@@log.info(act)
                p.id = playerEntry["player"]["destinyUserInfo"]["membershipId"]
                p.name = playerEntry["player"]["destinyUserInfo"]["displayName"]
                p.playerIcon = @@bungieURL + playerEntry["player"]["destinyUserInfo"]["iconPath"]
                p.score = playerEntry["score"]["basic"]["displayValue"]
                p.k = playerEntry["values"]["kills"]["basic"]["displayValue"]
                p.a = playerEntry["values"]["assists"]["basic"]["displayValue"]
                p.d = playerEntry["values"]["deaths"]["basic"]["displayValue"]
                p.kd = playerEntry["values"]["killsDeathsRatio"]["basic"]["displayValue"]
                p.completed = playerEntry["values"]["completed"]["basic"]["value"] == 1
                players.push(p)
            end
        end
        return players
    end

end
