class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  @@apikey = "950901f3a7b24a1082a9d47bb7b0a1b3"
  @@bungieURL = "http://www.bungie.net"
  @@log = Logger.new(STDOUT)
  
  protected def jsonCall(url)
    @@log.debug("calling #{url}")
    response = RestClient.get(url, {"X-API-Key" => @@apikey})
    @@log.debug("received response")
    json = response.body
    data = JSON.parse(json)
    return data
  end
  
  protected def noErrors(data)
    #@@log.info(data)
    return data["ErrorCode"] == 1
  end
end
