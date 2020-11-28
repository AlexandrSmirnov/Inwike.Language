class Admin::RequestsController < ApplicationController  
  force_ssl if Rails.env.production?
  before_filter :authenticate_user!
  layout "admin"
  
  def index
    @current_page = (params[:page] || 1).to_i
    @requests = Request.
                  order(id: :desc).
                  page(@current_page)
    @pages_count = Request.
                    pages_count
  end
  
end
