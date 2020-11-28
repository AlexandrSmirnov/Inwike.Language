class Admin::OpinionsController < ApplicationController
  force_ssl if Rails.env.production?
  before_filter :authenticate_user!
  layout "admin"
  
  # Список отзывов
  def index
    @current_page = (params[:page] || 1).to_i
    @opinions = Opinion.
                  page(@current_page)
    @pages_count = Opinion.
                    pages_count
  end
    
  # Страница создания отзыва
  def new
    @opinion = Opinion.new
  end
  
  # Непосредственно создание
  def create
    @opinion = Opinion.new(opinion_params)
    
    if @opinion.save
      redirect_to admin_opinions_path      
    else
      render 'new'      
    end    
  end
  
  # Страница редактирования отзыва
  def edit
    @opinion = Opinion.find(params[:id])
  end
    
  # Непосредственно редактирование
  def update
    @opinion = Opinion.find(params[:id])
    
    if @opinion.update(opinion_params)
      redirect_to admin_opinions_path     
    else
      render 'edit'        
    end    
  end
  
  # Непосредственно удаление
  def destroy
    @opinion = Opinion.find(params[:id])
    @opinion.destroy
    
    redirect_to admin_opinions_path
  end
  
  private
  def opinion_params
    params.require(:opinion).permit(:student_name, :tutor_id, :service_id, :fb_link, :vk_link, :progress, :text)
  end
  
end
