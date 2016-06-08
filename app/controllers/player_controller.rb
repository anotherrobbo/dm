class PlayerController < ApplicationController
    
    protected def getPlayer(system, name)
        p = Player.new
        p.system = system
        p.systemCode = getSystemCode(system)
        p.name = name
        p.id = getId(p.systemCode, p.name)
        p.chars = getChars(p.systemCode, p.id)
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
    
    protected def getChars(systemCode, id)
        data = jsonCall(@@bungieURL + "/Platform/Destiny/#{systemCode}/Account/#{id}/Summary/")
        chars = Array.new
        data["Response"]["data"]["characters"].each { |char| chars.push(createChar(char)) }
        return chars
    end
    
    private def createChar(theChar)
        c = Char.new
        c.id = theChar["characterBase"]["characterId"]
        c.classType = theChar["characterBase"]["classType"]
        return c
    end

end
