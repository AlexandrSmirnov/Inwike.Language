class Admin::ServicesController < ApplicationController  
  force_ssl if Rails.env.production?
  before_filter :authenticate_user!
  layout "admin"
  
  
  def index
    @services_categories = ServicesCategory.all
    @services = Service.includes(:services_category).all
  end
      
  
  def new
    @service = Service.new
  end
  
  
  def create
    @service = Service.new(services_params)
    
    if @service.save
      redirect_to admin_services_path      
    else
      render 'new'      
    end    
  end
  
  
  def edit
    @service = Service.find(params[:id])
  end
    
  
  def update
    @service = Service.find(params[:id])
    
    if @service.update(services_params)
      redirect_to admin_services_path     
    else
      render 'edit'        
    end    
  end  
  
  
  def destroy
    @service = Service.find(params[:id])
    @service.destroy
    
    redirect_to admin_services_path
  end
  
  
  private
  def services_params
    params.require(:service).permit(:name, :name_en, :url, :services_category_id, :sort_index, :show_on_main, :text, :text_en, :text_right, :text_right_en, :short_text, :short_text_en, :advanced_education, classes: [])    
  end
  
end
