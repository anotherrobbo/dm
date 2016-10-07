class ActivityController < PlayerController
    
    def activityDetails
        activityStats = getActivityStats(params[:id])
        render json: activityStats
    end
    
    def singleActivity
        @model = params[:id]
    end
    
    private def getActivityStats(id)
        a = ActivityStats.new
        data = jsonCall(@@bungieURL + "/Platform/Destiny/Stats/PostGameCarnageReport/#{id}/")
        # Not all have teams
        if data["Response"]["data"]["teams"] == nil || data["Response"]["data"]["teams"].empty?
            a.playerStats = getPlayerStats(data["Response"]["data"], nil);
        else
            a.teamStats = getTeamStats(data["Response"]["data"]);
        end
        act = data["Response"]["data"]
        a.id = id
        a.period = DateTime.parse(act["period"])
        useType = act["activityDetails"]["activityTypeHashOverride"] > 0 && act["activityDetails"]["mode"] != 4
        a.activityTypeHash = useType ? act["activityDetails"]["activityTypeHashOverride"] : nil
        a.activityHash = act["activityDetails"]["referenceId"]
        a.activityName = getDef("activity", a.activityHash)["activityName"]
        iconUrl = nil
        if a.activityTypeHash != nil
            a.activityType = getDef("activityType", a.activityTypeHash)["activityTypeName"]
            iconUrl = getDef("activityType", a.activityTypeHash)["icon"]
        else 
            iconUrl = getDef("activity", a.activityHash)["icon"]
        end
        # iconUrl can be nil if activity is classified
        if iconUrl != nil
            a.activityIcon = @@bungieURL + iconUrl
        end
        return a
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
        #@@log.info("Get player stats #{teamId}")
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
                p.kVal = playerEntry["values"]["kills"]["basic"]["value"]
                p.a = playerEntry["values"]["assists"]["basic"]["displayValue"]
                p.d = playerEntry["values"]["deaths"]["basic"]["displayValue"]
                p.kd = playerEntry["values"]["killsDeathsRatio"]["basic"]["displayValue"]
                p.completed = playerEntry["values"]["completed"]["basic"]["value"] == 1
                players.push(p)
            end
        end
        # Sort by score then kills
        players.sort! { |a, b| [b.scoreVal,b.kVal] <=> [a.scoreVal,a.kVal] }
        return players
    end

end
