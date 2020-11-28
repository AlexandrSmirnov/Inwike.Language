class Tutor::StudentsController < ApplicationController
  force_ssl if Rails.env.production?
  before_filter :authenticate_user!
  layout "admin"
  
  # Страница списка учеников
  def index
    @students = current_user.all_students
    @class_types = current_user.class_type.all
  end
    
  # Страница создания пользователя
  def new
    @student = User.new
  end
  
  # Непосредственно создание
  def create
    @student = current_user.students.create(student_lease_params)
    @student.lease = true
    @student.roles = ['student']
        
    if @student.save
      redirect_to tutor_users_path      
    else
      render 'new'      
    end    
  end
  
  # Страница редактирования ученика
  def edit
    @student = User.find(params[:id])
    @class_types = current_user.class_type.all
    
    unless current_user.students.include?(@student)
      redirect_to tutor_users_path
    end    
  end
  
  # Непосредственно редактирование
  def update
    @student = User.find(params[:id])
    
    unless current_user.students.include?(@student)
      redirect_to tutor_users_path
    end
    
    if params[:user][:password].blank?
      params[:user].delete(:password)
    end
    
    parameters = @student.lease ? student_lease_params : student_params
    if @student.update(parameters)
      redirect_to tutor_users_path     
    else
      render 'edit'        
    end    
  end
  
  # Непосредственно удаление
  def destroy
    @student = User.find(params[:id])
        
    if current_user.lease && current_user.students.include?(@student) && @student.lease
      @student.destroy
    end
    
    redirect_to tutor_users_path
  end
  
  private
  def student_params
    params.require(:user).permit(:quizlet_id)
  end 
  
  private
  def student_lease_params
    params.require(:user).permit(:name, :email, :password, :quizlet_id, class_type_ids: [], class_type_list: [], class_type_costs: [])
  end 
  
end
