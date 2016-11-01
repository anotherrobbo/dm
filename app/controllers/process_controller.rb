class ProcessController < PlayerController
    
    def pollProcess
        proc = Rails.cache.fetch(params[:id])
        render json: proc
    end

end
