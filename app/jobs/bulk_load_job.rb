require 'player_record'
require 'activity_record'
require 'activity'

class BulkLoadJob < GameJob
    include SuckerPunch::Job
    workers 4

    def perform(procId)
        players = PlayerRecord.order(matchesCount: :desc, overviewCount: :desc)
        players.each do |player|
            if player.matchesCount == 0
                @@log.info("#{player.name} had a matchesCount of 0, ending bulk load")
                break
            end
            proc = Rails.cache.fetch(procId)
            proc.current = player.name
            Rails.cache.write(procId, proc, expires_in: 5.minutes)
            chars = getChars(getSummaryData(player.systemCode, player.id))
            getGamesForAccount(procId, player.systemCode, player, chars)
        end

        proc = Rails.cache.fetch(procId)
        proc.running = false
        Rails.cache.write(procId, proc, expires_in: 5.minutes)
    end
    
    private def getGamesForAccount(procId, systemCode, pr, chars)
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
            
            activityRecord.activities = getGamesForChar(systemCode, pr.id, activityRecord, count)
            # Kick off a new job to save the activity record
            SaveJob.perform_async(activityRecord)
        end

        return games
    end

end