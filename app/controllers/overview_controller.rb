class OverviewController < ApplicationController

    def show
        p = Player.new
        p.system = params[:system]
        case p.system
            when "ps"
                p.systemCode = 2
            when "xb"
                p.systemCode = 1
        end
        p.name = params[:name]
        p.id = getId(p.systemCode, p.name)
        @model = p
    end
    
    private def getId(systemCode, name)
        log = Logger.new(STDOUT)
        url = "http://www.bungie.net/Platform/Destiny/SearchDestinyPlayer/#{systemCode}/#{name}/"
        response = RestClient.get(url, {"X-API-Key" => @@apikey})
        json = response.body
        data = JSON.parse(json)
        #log.info(data["Response"].empty?)
        return (data["Response"].empty?) ? nil : data["Response"][0]["membershipId"]
    end

end
