class Admin::ServicesCategoriesController < ApplicationController
  force_ssl if Rails.env.production?
  before_filter :authenticate_user!
  layout "admin"
  
  def new
    @services_category = ServicesCategory.new
  end
  
  
  def create
    @services_category = ServicesCategory.new(services_category_params)    
    
    if @services_category.save
      redirect_to admin_services_path      
    else
      render 'new'      
    end    
  end
    
  
  def edit
    @services_category = ServicesCategory.find(params[:id])
  end
    
  
  def update
    @services_category = ServicesCategory.find(params[:id])
    
    if @services_category.update(services_category_params)
      redirect_to admin_services_path     
    else
      render 'edit'        
    end    
  end  
  
  
  def destroy
    @services_category = ServicesCategory.find(params[:id])
    @services_category.destroy
    
    redirect_to admin_services_path    
  end
    
  
  private
  def services_category_params
    params.require(:services_category).permit(:name, :name_en, :text, :text_en, :icon_class)    
  end
  
end
