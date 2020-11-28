class Admin::UsersController < ApplicationController
  force_ssl if Rails.env.production?
  before_filter :authenticate_user!
  layout "admin"
  
  # Список пользователей
  def index
    @current_page = (params[:page] || 1).to_i
    @users = User.
              select("*, (SELECT COUNT(*) FROM schedules LEFT JOIN payments ON schedules.payment_id = payments.id WHERE (schedules.student_id = users.id OR schedules.user_id = users.id) AND state = 9 AND (pay_time IS NULL OR pay_time = 0) AND (free IS NULL OR free = 0)) AS debts").
              debts_filter(user_filter_params).
              role_filter(user_filter_params).
              name_filter(user_filter_params).
              page(@current_page, params[:sort] || {})
    @pages_count = User.
                    debts_filter(user_filter_params).
                    role_filter(user_filter_params).
                    name_filter(user_filter_params).
                    pages_count
    @filter_params = user_filter_params || {}
  end
    
  # Страница создания пользователя
  def new
    @user = User.new
  end
  
  # Непосредственно создание
  def create
    @user = User.new(user_params)
    
    if @user.save
      redirect_to admin_users_path      
    else
      render 'new'      
    end    
  end
  
  # Страница редактирования пользователя
  def edit
    @user = User.find(params[:id])
    @debts = @user.has_role?(:tutor) ? User.with_unpaided_lessons_with_tutor(@user.id) : @user.student_schedule.carried_out.not_paid    
    @benefits = nil
    if @user.has_role?(:tutor)
      lessons_last_month = Schedule.tutor(@user.id).time_between(Time.now.beginning_of_month.to_i, Time.now.to_i).assigned
      @benefits = Schedule.payments_statistics(lessons_last_month, @user)
    end
  end
  
  # Непосредственно редактирование
  def update
    @user = User.find(params[:id])
    @debts = @user.has_role?(:tutor) ? User.with_unpaided_lessons_with_tutor(@user.id) : @user.student_schedule.carried_out.not_paid
    
    if params[:user][:password].blank?
      params[:user].delete(:password)
    end
    
    if @user.update(user_params)
      redirect_to admin_users_path     
    else
      render 'edit'        
    end        
  end
       
  # Непосредственно удаление
  def destroy
    @user = User.find(params[:id])
    @user.destroy
    
    redirect_to admin_users_path
  end
  
  
  private
  def user_params
    params.require(:user).permit(:name, :email, :password, :role, :locale, :time_zone, :board, :fee, :quizlet_id, :transfer_fee, :lease, roles: [], tutor_ids: [], class_type_ids: [], class_type_list: [], class_type_costs: [], class_type_fees: [])
  end 
      
  private
  def user_filter_params
    return nil if not params.has_key?(:filter)
    params.require(:filter).permit(:role, :name, :with_debts)
  end
end
