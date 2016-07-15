class ActivityController < PlayerController
    
    def activityDetails
        activityStats = getActivityStats(params[:id])
        render json: activityStats
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
