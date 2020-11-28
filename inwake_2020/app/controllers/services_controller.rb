class ServicesController < ApplicationController
  layout "inner"
  before_filter :set_breadcrumb
    
  def index    
    @services = Service.order(:services_category_id, :sort_index).all
    
    template = if ege? then "index_ege" else "index" end
    render template
  end
  
  def show    
    @service = Service.find_by_url(params[:url]) or not_found
    name = ((I18n.locale == 'en') && @service.name_en.present?) ? @service.name_en : @service.name
    add_breadcrumb name, service_path( :url => @service.url )
  end
  
  private
  
  def set_breadcrumb        
    add_breadcrumb I18n.t("main.main"), :root_path
    if ege?
      add_breadcrumb I18n.t("services.servicesege"), :services_path
    else
      add_breadcrumb I18n.t("services.services"), :services_path
    end
  end
  
end
