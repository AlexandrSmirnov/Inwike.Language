class Tutor::ClassTypesController < ApplicationController
  force_ssl if Rails.env.production?
  before_filter :authenticate_user!
  layout "admin"
  
  def new    
    @class_type = ClassType.new
    @tutor_class = nil
  end
  
  def create   
    @class_type = current_user.class_type.create(class_types_params)
    
    if @class_type && @class_type.tutor_classes.update_all(tutor_classes_params)
      redirect_to tutor_users_path      
    else
      render 'new'
    end     
  end
  
  def edit
    @class_type = ClassType.find(params[:id])
    @tutor_class = @class_type.tutor_classes.first ? @class_type.tutor_classes.first : nil
  end
    
  def update
    @class_type = ClassType.find(params[:id])
    
    if @class_type.update(class_types_params) && @class_type.tutor_classes.update_all(tutor_classes_params)
      redirect_to tutor_users_path     
    else
      render 'edit'        
    end    
  end
  
  def destroy
    @class_type = ClassType.find(params[:id])
    @class_type.destroy
    
    redirect_to tutor_users_path
  end
  
  private
  def class_types_params
    params.require(:class_type).permit(:name)    
  end
  
  def tutor_classes_params
    params.require(:tutor_class).permit(:cost)    
  end
  
end
