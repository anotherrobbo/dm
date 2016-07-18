class MatchJob < PlayerController
    include SuckerPunch::Job
    workers 4

    def perform(procId, systemCode, id1, id2, c1, c2)
        g1 = getGamesForAccount(procId, systemCode, id1, c1)
        g2 = getGamesForAccount(procId, systemCode, id2, c2)
        matches = getMatches(g1, g2)
        # Reverse sort by time
        matches.sort! { |a, b| b.time <=> a.time }
        
        proc = Rails.cache.fetch(procId)
        proc.result = matches
        Rails.cache.write(procId, proc, expires_in: 5.minutes)
    end
    
    private def getGamesForAccount(procId, systemCode, id, chars)
        count = 250
        games = Hash.new
        chars.each do |char|
            games.merge!(getGamesForChar(systemCode, id, char))
            # TODO sync this if we're doing it on multiple threads
            proc = Rails.cache.fetch(procId)
            proc.progress = proc.progress + 1
            Rails.cache.write(procId, proc, expires_in: 5.minutes)
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
                a.activityIcon = @@bungieURL + getDef(a.prefix, a.activityHash)["icon"]
                a.activityName = getDef(a.prefix, a.activityHash)["#{a.prefix}Name"]
                a.result = g.result
                a.team = g.team
                a.kd = g.kd
                a.sameTeam = g.team == nil || g.team == g2[key].team
                matches.push(a)
            end
        end
        return matches
    end

end