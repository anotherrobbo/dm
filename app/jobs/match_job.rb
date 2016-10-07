require 'player_record'
require 'activity_record'
require 'activity'

class MatchJob < PlayerController
    include SuckerPunch::Job
    workers 4

    def perform(procId, systemCode, pr1, pr2, c1, c2, forceCheck)
        g1 = getGamesForAccount(procId, systemCode, pr1, c1, forceCheck)
        if pr1.id == pr2.id
            matches = getMatches(g1, g1)
        else
            g2 = getGamesForAccount(procId, systemCode, pr2, c2, forceCheck)
            matches = getMatches(g1, g2)
        end
        # Reverse sort by period
        matches.sort! { |a, b| b.period <=> a.period }
        
        proc = Rails.cache.fetch(procId)
        proc.result = matches
        Rails.cache.write(procId, proc, expires_in: 5.minutes)
    end
    
    private def getGamesForAccount(procId, systemCode, pr, chars, forceCheck)
        count = 250
        games = Hash.new
        chars.each do |char|
            activityRecord = findActivityRecord(pr, char.id)
            refresh = true
            if activityRecord != nil
                # lower count as we already have records and lower counts are quicker
                count = 50
            else
                activityRecord = ActivityRecord.new
                activityRecord.player_record_id = pr.id
                activityRecord.id = char.id
                activityRecord.activities = Hash.new
            end
            
            # check if we already found records in the last 10 minutes
            if activityRecord.updated_at != nil && activityRecord.updated_at > 10.minutes.ago && !forceCheck
                @@log.info("Last updated less than 10 minutes ago so skipping load - #{activityRecord.updated_at}")
            else
                activityRecord.activities = getGamesForChar(systemCode, pr.id, activityRecord, count)
                # Kick off a new job to save the activity record
                SaveJob.perform_async(activityRecord)
            end
            games.merge!(activityRecord.activities)
            # TODO sync this if we're doing it on multiple threads
            proc = Rails.cache.fetch(procId)
            proc.progress = proc.progress + 1
            Rails.cache.write(procId, proc, expires_in: 5.minutes)
        end
        pr.increment(:matchesCount)
        # Kick off a new job to save the player record
        SaveJob.perform_async(pr)
        return games
    end
    
    private def findActivityRecord(pr, cid)
        pr.activityRecords.each do |ar|
            if ar.id == cid
                return ar
            end
        end
        return nil
    end
    
    private def getGamesForChar(systemCode, id, char, count)
        # and now we assume that the ids are ALWAYS increasing... :S
        max = 0
        games = char.activities
        if games.length > 0
            max = games.keys.sort{ |x,y| y <=> x }[0]
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
                a.activityTypeHash = useType ? act["activityDetails"]["activityTypeHashOverride"] : nil
                a.activityHash = act["activityDetails"]["referenceId"]
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
        return games
    end
    
    private def getMatches(g1, g2)
        h1 = g1
        h2 = g2
        matches = Array.new
        h1.each do |key, g|
            if h2.has_key?(key) 
                a = ActivityDetail.new
                a.id = g.id
                a.period = g.period
                a.activityTypeHash = g.activityTypeHash
                a.activityHash = g.activityHash
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