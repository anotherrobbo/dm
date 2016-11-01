require 'player_record'
require 'activity_record'
require 'activity'

class GameJob < PlayerController
    
    def findActivityRecord(pr, cid)
        pr.activityRecords.each do |ar|
            if ar.id == cid
                return ar
            end
        end
        return nil
    end
    
    def getGamesForChar(systemCode, id, char, count)
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

end