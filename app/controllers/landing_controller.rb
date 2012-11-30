class LandingController < ApplicationController
  def index
    @charts = Chart.demo.all
  end
end
