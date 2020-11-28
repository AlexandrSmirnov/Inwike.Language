class ApplicationController < ActionController::Base
  
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :set_locale, :set_timezone
  before_filter :configure_permitted_parameters, if: :devise_controller?
  
    
  def index    
    @country = 'RU'
    if request.remote_ip != '127.0.0.1'
      ip_data = GeoIP.new('lib/GeoIP.dat').country(request.remote_ip)
      @country = ip_data.country_code2
    end

    render layout: "main_ege" and return if ege?
    render layout: "main"
  end
  
 
  def set_locale        
    if extract_locale_from_domain
      I18n.locale = extract_locale_from_domain
    else  
      if current_user
        I18n.locale = current_user.locale? ? current_user.locale : I18n.default_locale
      else  
        I18n.locale = I18n.default_locale
      end
    end
  end
  
  def set_timezone
    if current_user and current_user.time_zone?
      Time.zone = current_user.time_zone
    else
      Time.zone = 'UTC'
    end
  end
  
  def after_sign_in_path_for(resource)    
    
    # Определяем пути для переадресации пользователя после авторизации
    # Задаем порядок приоритета для ролей учетных записей
    
    if (current_user.has_role? :admin) && (current_user.has_role? :tutor)
      tutor_calendar_index_path
     #tutor_lesson_path
    else
      if (current_user.has_role? :admin) || (current_user.has_role? :tutor)
        if current_user.has_role? :tutor
          tutor_lesson_path
        else
          admin_users_path      
        end
      elsif current_user.has_role? :student
        student_lesson_path
       #student_calendar_index_path
      else
        user_settings_path      
      end
    end
    
#    if current_user.has_role? :tutor
#      tutor_lesson_path
##      tutor_calendar_index_path
#    elsif current_user.has_role? :admin
#      admin_users_path
#    elsif current_user.has_role? :student
#      student_lesson_path
##      student_calendar_index_path
#    else
#      user_settings_path
#    end
    
  end
  
  def after_sign_out_path_for(resource_or_scope)    
    root_path
  end
  
  def extract_locale_from_domain
    parsed_locale = request.host.split('.').first
    I18n.available_locales.include?(parsed_locale.to_sym) ? parsed_locale  : nil
  end
  
  def ege?
    return true if Rails.configuration.project == 'ege'
    false
  end
  
  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end
  
  def report_problem   
    result = 0 
        
    if current_user
      report = current_user.error_report.new(params.require(:error_report).permit(:description, :file, :messages, :client_info))  
      if report.save
        result = 1
      end
    end
    
    render :json => { :result => result }       
  end
  
  def sitemap
#    @tutors = Tutor.all
    render :layout => false
  end
  
  def user_data
    render nothing and return if not current_user
    
    render :json => { 
      :id => current_user.id, 
      :email => current_user.email, 
      :opentok_id => current_user.opentok_id,
      :role => if current_user.has_role? :tutor then 'tutor' elsif current_user.has_role? :student then 'student' else '' end,
      :chat_users => current_user.get_chat_users
    }      
  end
  
  protected
  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) {|u| u.permit(:email, :password, :password_confirmation, roles: [])}
  end  
  
end
