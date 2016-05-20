class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  @@apikey = "950901f3a7b24a1082a9d47bb7b0a1b3"
end
