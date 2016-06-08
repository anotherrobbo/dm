class SearchController < ApplicationController
    def search
        @@log.info(params)
        name = params[:un]
        responses = getResponses(name)
        results = parseResponses(responses)
        render json: results
    end
  
    private def getResponses(name)
        data = jsonCall(@@bungieURL + "/Platform/Destiny/SearchDestinyPlayer/All/#{name}/")
        #@@log.info(data["Response"].empty?)
        return data["Response"]
    end
    
    private def parseResponses(responses)
        players = Array.new
        #@@log.info(responses)
        responses.each { |member| players.push(createPlayer(member)) }
        return players
    end
    
    private def createPlayer(member)
        p = Player.new
        p.systemCode = member["membershipType"]
        case p.systemCode
            when 2
                p.system = "ps"
            when 1
                p.system = "xb"
        end
        p.name = member["displayName"]
        p.id = member["membershipId"]
        return p
    end
end
