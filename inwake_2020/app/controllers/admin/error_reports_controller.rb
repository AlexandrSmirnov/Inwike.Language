class Admin::ErrorReportsController < ApplicationController
  force_ssl if Rails.env.production?
  before_filter :authenticate_user!
  layout "admin"
  
  def index
    @current_page = (params[:page] || 1).to_i
    @error_reports = ErrorReport.
                  all.
                  order(id: :desc).
                  page(@current_page)
    @pages_count = ErrorReport.
                    pages_count                  
  end
  
  def show
    @report = ErrorReport.find(params[:id])
    @log = []
    @client_info = []
    if @report.messages
      @log = JSON.parse(@report.messages)
      @client_info = JSON.parse(@report.client_info)
    end
  end
  
  
end
