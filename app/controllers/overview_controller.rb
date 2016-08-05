class OverviewController < PlayerController

    def show
        @model = getPlayer(params[:system], params[:name])
        PlayerRecord.find_by!(system: @model.system, name: @model.name).increment!(:overviewCount)
    end

end
