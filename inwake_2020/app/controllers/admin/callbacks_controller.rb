class Admin::CallbacksController < ApplicationController
  force_ssl if Rails.env.production?
  before_filter :authenticate_user!
  layout "admin"
  
  def index
    @current_page = (params[:page] || 1).to_i
    @callbacks = Call_back.
                  order(id: :desc).
                  page(@current_page)
    @pages_count = Call_back.
                    pages_count
  end
end
