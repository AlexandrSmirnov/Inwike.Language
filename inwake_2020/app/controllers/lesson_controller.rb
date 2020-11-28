class LessonController < ApplicationController
  
  before_filter :authenticate_user!
  layout "admin"
  
  def index    
    @chat_users = Array.new    
    if current_user.has_role? :tutor
      current_user.all_students.each { |student| @chat_users << ("#{student.id}: '#{student.name}'") }
    end     
    if current_user.has_role? :student
      current_user.all_tutors.each { |tutor| @chat_users << ("#{tutor.id}: '#{tutor.name}'") }
    end    
    
  end
  
  def get_nearest
    nearest_lesson = current_user.get_nearest_lesson    
    render :json => nearest_lesson
  end
  
  def enter_room
    if not User.exists?(params[:user_id])
      render(:json => {:result => 0}) and return
    end
    
    render :json => {:result => 0}
  end

  def enter_group
    lesson = Schedule.find(params[:lesson_id])

    render :json => {:result => 0}
  end
  
end
