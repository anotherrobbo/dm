class OverviewController < PlayerController

    def show
        @model = getPlayer(params[:system], params[:name])
    end

end
