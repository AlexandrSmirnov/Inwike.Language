class Admin::ClassTypesController < ApplicationController
  force_ssl if Rails.env.production?
  before_filter :authenticate_user!
  layout "admin"
  
  def index
    @class_types = ClassType.all
  end
  
  def new    
    @class_type = ClassType.new
  end
  
  def create   
    @class_type = ClassType.new(class_types_params)
    
    if @class_type.save
      redirect_to admin_class_types_path      
    else
      render 'new'      
    end     
  end
  
  def edit
    @class_type = ClassType.find(params[:id])
  end
    
  def update
    @class_type = ClassType.find(params[:id])
    
    if @class_type.update(class_types_params)
      redirect_to admin_class_types_path     
    else
      render 'edit'        
    end    
  end
  
  def destroy
    @class_type = ClassType.find(params[:id])
    @class_type.destroy
    
    redirect_to admin_class_types_path
  end
  
  private
  def class_types_params
    params.require(:class_type).permit(:name)    
  end
  
end
