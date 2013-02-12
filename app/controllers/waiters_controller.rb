class WaitersController < ApplicationController
  def create
    begin
      @waiter = Waiter.create! params[:waiter]
      
      respond_to { |format|
        format.json {
          render json: @waiter
        }
      }
    rescue
      respond_to { |format|
        format.json {
          render json: {}, status: :unprocessable_entity
        }
      }
    end
  end
end
