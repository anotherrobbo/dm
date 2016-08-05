class PlayerController < ApplicationController
    
    def getPlayerRecord(system, name)    
        pr = PlayerRecord.find_by(system: system, name: name)
        if pr == nil
            pr = PlayerRecord.new
            pr.system = system
            pr.systemCode = getSystemCode(system)
            pr.name = name
            pr.id = getId(pr.systemCode, pr.name)
            pr.save
        end
        
        return pr
    end
    
    protected def getPlayer(system, name)    
        pr = getPlayerRecord(system, name)
        
        p = Player.new        
        p.id = pr.id
        p.system = pr.system
        p.systemCode = pr.systemCode
        p.name = pr.name
        
        summary = getSummaryData(p.systemCode, p.id)
        
        p.clan = summary["clanName"]
        p.clanTag = summary["clanTag"]
        p.grimoire = summary["grimoireScore"]
        p.chars = getChars(summary)
        return p
    end
    
    protected def getSystemCode(system)
        case system
            when "ps"
                return 2
            when "xb"
                return 1
        end
        return 0
    end
    
    protected def getId(systemCode, name)
        data = jsonCall(@@bungieURL + "/Platform/Destiny/SearchDestinyPlayer/#{systemCode}/#{name}/")
        #@@log.info(data["Response"].empty?)
        return (data["Response"].empty?) ? nil : data["Response"][0]["membershipId"]
    end
    
    protected def getSummaryData(systemCode, id)
        data = jsonCall(@@bungieURL + "/Platform/Destiny/#{systemCode}/Account/#{id}/Summary/")
        #@@log.info(data)
        summary = nil
        if noErrors(data)
            summary = data["Response"]["data"]
        end
        return summary
    end
    
    protected def getChars(summary)
        chars = Array.new
        summary["characters"].each { |char| chars.push(createChar(char)) }
        return chars
    end
    
    private def createChar(theChar)
        c = Char.new
        c.id = theChar["characterBase"]["characterId"]
        c.class = getDef2("class", "classDefinition", theChar["characterBase"]["classHash"])["className"]
        c.race = getDef("race", theChar["characterBase"]["raceHash"])["raceName"]
        c.gender = getDef("gender", theChar["characterBase"]["genderHash"])["genderName"]
        c.light = theChar["characterBase"]["powerLevel"]
        c.level = theChar["levelProgression"]["level"]
        c.emblem = @@bungieURL + theChar["emblemPath"]
        c.bg = @@bungieURL + theChar["backgroundPath"]
        return c
    end
    
    protected def getDef(type, hash)
        return getDef2(type, type, hash)
    end
    
    protected def getDef2(type, typeDef, hash)
        return Rails.cache.fetch("#{type}-#{hash}") do
            @@log.info("Loading #{type}/#{hash}")
            data = jsonCall(@@bungieURL + "/Platform/Destiny/Manifest/#{type}/#{hash}/")
            ##@@log.info(data["Response"]["data"])
            data["Response"]["data"][typeDef]
        end
    end

end
