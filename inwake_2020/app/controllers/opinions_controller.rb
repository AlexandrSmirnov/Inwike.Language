class OpinionsController < ApplicationController
  
  def index
    add_breadcrumb I18n.t("main.main"), :root_path
    add_breadcrumb I18n.t("main.opinions"), :opinions_path    
    
    @about_system = false
    @current_page = (params[:page] || 1).to_i
    @opinions = Opinion.order(tutor_id: :desc).tutor_assigned.page(@current_page)
    @pages_count = Opinion.tutor_assigned.pages_count
    render layout: "application"        
  end  
  
  def index_system
    add_breadcrumb I18n.t("main.main"), :root_path
    add_breadcrumb I18n.t("main.opinions"), :opinions_system_path    
    
    @about_system = true
    @current_page = (params[:page] || 1).to_i
    @opinions = Opinion.order(tutor_id: :desc).not_assigned.page(@current_page)
    @pages_count = Opinion.not_assigned.pages_count
    render 'index', layout: "application"        
  end  
  
end
