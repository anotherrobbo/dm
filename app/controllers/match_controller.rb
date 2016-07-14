class MatchController < PlayerController

    def matchPlayers
        system = params[:system]
        @model = getPlayer(system, params[:name])
        @model2 = getPlayer(system, params[:name2])
    end
    
    def matchGames
        @@log.info("Cache location: " + Rails.cache.cache_path)
        g1 = getGamesForAccount(params[:systemCode], params[:id], getChars(params[:systemCode], params[:id]))
        g2 = getGamesForAccount(params[:systemCode], params[:id2], getChars(params[:systemCode], params[:id2]))
        matches = getMatches(g1, g2)
        # Reverse sort by time
        matches.sort! { |a, b| b.time <=> a.time }
        render json: matches
    end
    
    def matchDetails
        activityStats = getActivityStats(params[:id])
        render json: activityStats
    end
    
    private def getGamesForAccount(systemCode, id, chars)
        count = 250
        games = Hash.new
        chars.each do |char|
            games.merge!(getGamesForChar(systemCode, id, char))
        end
        return games
    end
    
    private def getGamesForChar(systemCode, id, char)
        games = Rails.cache.fetch("#{systemCode}-#{id}-#{char.id}") do
            Hash.new
        end
        # and now we assume that the ids are ALWAYS increasing... :S
        max = 0
        if games.length > 0
            max = games.keys.sort{ |x,y| y <=> x }[0]
            @@log.info("max = #{max}")
        end
        count = 250
        page = 0
        while 1
            @@log.info("#{page} - #{char.id}")
            #@@log.info(@@bungieURL + "/Platform/Destiny/Stats/ActivityHistory/#{systemCode}/#{id}/#{char.id}/?definitions=false&mode=None&page=#{page}&count=#{count}")
            data = jsonCall(@@bungieURL + "/Platform/Destiny/Stats/ActivityHistory/#{systemCode}/#{id}/#{char.id}/?definitions=false&mode=None&page=#{page}&count=#{count}")
            # Break if we've reached a page with no data
            if data["Response"]["data"]["activities"] == nil
                break
            end
            lastid = 0;
            data["Response"]["data"]["activities"].each do |act|
                lastid = act["activityDetails"]["instanceId"].to_i
                if lastid <= max
                    break
                end
                useType = act["activityDetails"]["activityTypeHashOverride"] > 0 && act["activityDetails"]["mode"] != 4
                a = Activity.new
                a.id = lastid
                a.period = act["period"]
                a.prefix = useType ? "activityType" : "activity"
                a.activityHash = useType ? act["activityDetails"]["activityTypeHashOverride"] : act["activityDetails"]["referenceId"]
                a.result = act["values"]["standing"] != nil ? 1 - act["values"]["standing"]["basic"]["value"] : act["values"]["completed"]["basic"]["value"]
                a.team = act["values"]["team"] != nil ? act["values"]["team"]["basic"]["displayValue"][0] : nil
                a.kd = act["values"]["killsDeathsRatio"] != nil ? act["values"]["killsDeathsRatio"]["basic"]["displayValue"] : nil
                games[a.id] = a
            end
            if lastid <= max
                break
            end
            page += 1
        end
        Rails.cache.write("#{systemCode}-#{id}-#{char.id}", games)
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
        return Rails.cache.fetch("#{prefix}-#{actHash}") do
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
                p.class = playerEntry["player"]["characterClass"]
                p.level = playerEntry["player"]["characterLevel"]
                p.light = playerEntry["player"]["lightLevel"]
                p.scoreVal = playerEntry["score"]["basic"]["value"]
                p.score = playerEntry["score"]["basic"]["displayValue"]
                p.k = playerEntry["values"]["kills"]["basic"]["displayValue"]
                p.a = playerEntry["values"]["assists"]["basic"]["displayValue"]
                p.d = playerEntry["values"]["deaths"]["basic"]["displayValue"]
                p.kd = playerEntry["values"]["killsDeathsRatio"]["basic"]["displayValue"]
                p.completed = playerEntry["values"]["completed"]["basic"]["value"] == 1
                players.push(p)
            end
        end
        # Sort by score then kills
        players.sort! { |a, b| [b.scoreVal,b.k] <=> [a.scoreVal,a.k] }
        return players
    end

end
