class MatchJob < PlayerController
    include SuckerPunch::Job
    workers 4

    def perform(procId, systemCode, id1, id2, c1, c2)
        g1 = getGamesForAccount(procId, systemCode, id1, c1)
        if id1 == id2
            matches = getMatches(g1, g1)
        else
            g2 = getGamesForAccount(procId, systemCode, id2, c2)
            matches = getMatches(g1, g2)
        end
        # Reverse sort by period
        matches.sort! { |a, b| b.period <=> a.period }
        
        proc = Rails.cache.fetch(procId)
        proc.result = matches
        Rails.cache.write(procId, proc, expires_in: 5.minutes)
    end
    
    private def getGamesForAccount(procId, systemCode, id, chars)
        count = 250
        games = Array.new
        chars.each do |char|
            charActivities = CharActivity.find_by_id(char.id)
            refresh = true
            if charActivities != nil
                # lower count as we already have records and lower counts are quicker
                count = 50
            else
                charActivities = CharActivity.new
                charActivities.id = char.id
                charActivities.activities = Array.new
            end
            
            # check if we already found records in the last 10 minutes
            if charActivities.updated_at != nil && charActivities.updated_at > 10.minutes.ago
                @@log.info("Last updated less than 10 minutes ago so skipping load - #{charActivities.updated_at}")
            else
                charActivities.activities = getGamesForChar(systemCode, id, charActivities, count)
                @@log.info(charActivities.changed?)
                if charActivities.new_record?
                    charActivities.save!
                else
                    charActivities.touch
                end
            end
            games.concat(charActivities.activities)
            # TODO sync this if we're doing it on multiple threads
            proc = Rails.cache.fetch(procId)
            proc.progress = proc.progress + 1
            Rails.cache.write(procId, proc, expires_in: 5.minutes)
        end
        return games
    end
    
    private def getGamesForChar(systemCode, id, char, count)
        # and now we assume that the ids are ALWAYS increasing... :S
        max = 0
        games = char.activities
        if games.length > 0
            max = games.sort{ |x,y| y.id <=> x.id }[0].id
            @@log.info("max = #{max}")
        end
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
                a.period = DateTime.parse(act["period"])
                a.prefix = useType ? "activityType" : "activity"
                a.activityHash = useType ? act["activityDetails"]["activityTypeHashOverride"] : act["activityDetails"]["referenceId"]
                a.result = act["values"]["standing"] != nil ? 1 - act["values"]["standing"]["basic"]["value"] : act["values"]["completed"]["basic"]["value"]
                a.team = act["values"]["team"] != nil ? act["values"]["team"]["basic"]["displayValue"][0] : nil
                a.kd = act["values"]["killsDeathsRatio"] != nil ? act["values"]["killsDeathsRatio"]["basic"]["displayValue"] : nil
                games.push(a)
            end
            if lastid <= max
                break
            end
            page += 1
        end
        return games
    end
    
    private def getMatches(g1, g2)
        h1 = g1.map { |x| [x.id, x] }.to_h
        h2 = g2.map { |x| [x.id, x] }.to_h
        matches = Array.new
        h1.each do |key, g|
            if h2.has_key?(key) 
                a = ActivityDetail.new
                a.id = g.id
                a.period = g.period
                a.prefix = g.prefix
                a.activityHash = g.activityHash
                a.activityIcon = @@bungieURL + getDef(a.prefix, a.activityHash)["icon"]
                a.activityName = getDef(a.prefix, a.activityHash)["#{a.prefix}Name"]
                a.result = g.result
                a.team = g.team
                a.kd = g.kd
                a.sameTeam = g.team == nil || g.team == h2[key].team
                matches.push(a)
            end
        end
        return matches
    end

end