require 'player_record'
require 'activity_record'
require 'activity'

class MatchJob < GameJob
    include SuckerPunch::Job
    workers 4

    def perform(procId, systemCode, pr1, pr2, c1, c2, forceCheck)
        g1 = getGamesForAccount(procId, systemCode, pr1, c1, forceCheck)
        if pr1.id == pr2.id
            @@log.info("Same id detected, getting matches with itself")
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
    
    private def getMatches(g1, g2)
        @@log.info("Picking out matches...")
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
        @@log.info("#{matches.length} Matches picked!")
        return matches
    end

end