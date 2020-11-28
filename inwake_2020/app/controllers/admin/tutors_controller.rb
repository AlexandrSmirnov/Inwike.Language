class Admin::TutorsController < ApplicationController
  force_ssl if Rails.env.production?
  before_filter :authenticate_user!
  layout "admin"
  
  # Список преподавателей
  def index
    @current_page = (params[:page] || 1).to_i
    @tutors = Tutor.
                eager_load(:service).
                name_filter(tutor_filter_params).
                page(@current_page)
    @pages_count = Tutor.
                    name_filter(tutor_filter_params).
                    pages_count                  
    @filter_params = tutor_filter_params || {}
  end
    
  # Страница создания преподавателя
  def new
    @tutor = Tutor.new
  end
  
  # Непосредственно создание
  def create
    @tutor = Tutor.new(tutor_params)
    
    if @tutor.save
      redirect_to admin_tutors_path      
    else
      render 'new'      
    end    
  end
  
  # Страница редактирования преподавателя
  def edit
    @tutor = Tutor.find(params[:id])
  end
  
  # Непосредственно редактирование
  def update
    @tutor = Tutor.find(params[:id])
    
    if @tutor.update(tutor_params)
      redirect_to admin_tutors_path     
    else
      render 'edit'        
    end    
  end
  
  # Непосредственно удаление
  def destroy
    @tutor = Tutor.find(params[:id])
    @tutor.destroy
    
    redirect_to admin_tutors_path
  end
  
  # Пересоздает миниатюры фотографий
  def recreate_thumbs
    Tutor.all.each do |tutor|
      tutor.photo.recreate_versions! if tutor.photo?
    end
    
    redirect_to admin_tutors_path
  end
  
  private
  def tutor_params
    params.require(:tutor).permit(:name, :url, :job, :teach, :user_id, :dialect, :russian_language, :languages, :education, :employment, :location, :photo, :video, :short_text, :text, :text_right, :short_text_en, :text_en, :text_right_en, :sort_index, :native_speaker, :hidden, :experience, service_ids: [], service_list: [], service_recommendeds: [])
  end
  
  def tutor_filter_params
    return nil if not params.has_key?(:filter)
    params.require(:filter).permit(:name)
  end
  
end
