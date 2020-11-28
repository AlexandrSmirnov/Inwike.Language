require "tutor_time_zone"
class TutorsController < ApplicationController
  before_filter :set_breadcrumb
      
  def index
    @current_page = (params[:page] || 1).to_i
    
    if ege?
      @filter_params = tutors_filter_ege_params || {}
      @tutors = Tutor.eager_load(:service).active.filter_classes_group(tutors_filter_ege_params).filter_ege(tutors_filter_ege_params).page(@current_page)
      @pages_count = Tutor.active.filter_classes_group(tutors_filter_ege_params).filter_ege(tutors_filter_ege_params).pages_count
    else
      @filter_params = tutors_filter_params || {}
      @tutors = Tutor.active.filter(tutors_filter_params).page(@current_page)
      @pages_count = Tutor.active.filter(tutors_filter_params).pages_count
    end
    
    @services = Service.all(:include => :services_category)
    @grouped_options = @services.inject({}) do |options, service|
      (options[service.services_category ? service.services_category.name : nil] ||= []) << [service.name, service.id]
      options
    end
    puts @grouped_options
  end
  
  def show
    @tutor = Tutor.find_by_url(params[:url]) or not_found
    add_breadcrumb @tutor.name, tutor_path(:url => @tutor.url)
  end
  
    
  private
  
  def tutors_filter_params
    return nil if not params.has_key?(:filter)
    params.require(:filter).permit(:dialect, :russian_language, :native_speaker, :service)
  end
  
  def tutors_filter_ege_params
    return nil if not params.has_key?(:filter)
    params.require(:filter).permit(:services_category, :classes_group, :advanced_education)
  end
  
  def set_breadcrumb    
    add_breadcrumb I18n.t("main.main"), :root_path
    add_breadcrumb I18n.t("tutors.tutors"), :tutors_path
  end
  
end
