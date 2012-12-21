class PagesController < ApplicationController
  def show
    render "/pages/#{params[:id]}", layout: "application", locals: { cls: "pages" } rescue not_found
  end
end