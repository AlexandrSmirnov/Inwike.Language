class Student::HomeworkController < ApplicationController
  force_ssl if Rails.env.production?
  before_filter :authenticate_user!
  layout "admin"
  
  def index
    @homeworks = Schedule
    .select('*, (SELECT COUNT(1) FROM homeworks WHERE schedule_id = schedules.id) as homework_count, (SELECT COUNT(1) FROM homeworks WHERE schedule_id = schedules.id AND is_done = 1) as homework_done_count')
    .where('student_id = :student_id AND time + duration > :end_time', {student_id: current_user.id, end_time: Time.now.to_i - Rails.configuration.lesson_time_limit})
    .group('schedules.id')
    .order('schedules.time ASC')
    
    @nearest_homework = nil
    @nearest_tasks = nil
    @nearest_comments = nil
        
    if params.has_key?(:lesson) and Schedule.exists?(params[:lesson]) and Schedule.find(params[:lesson]).student_id == current_user.id
      @nearest_homework = Schedule.includes(:student).find(params[:lesson])      
    else  
      nearest_homework_array = Schedule.where('student_id = :student_id AND time + duration > :end_time', {student_id: current_user.id, end_time: Time.now.to_i - Rails.configuration.lesson_time_limit}).order(time: :asc).limit(1)
      if nearest_homework_array
        @nearest_homework = nearest_homework_array[0]
      end
    end
    
    if @nearest_homework
      @nearest_tasks = @nearest_homework.homework.all    
      @nearest_comments = @nearest_homework.comment.order(id: :desc)    
    end
  end
  
  def list
    end_time = ''
    if params[:end].to_i > 0
      end_time = "AND time < #{params[:end].to_i}"      
    end
    
    mode = ''
    if params[:mode] == 'actual'
      mode = "AND time + duration > #{Time.now.to_i - Rails.configuration.lesson_time_limit}"
    end
    if params[:mode] == 'archive'
      mode = "AND time + duration < #{Time.now.to_i - Rails.configuration.lesson_time_limit}"
    end
    
    @homeworks = Schedule.includes(:student)
    .select('*, (SELECT COUNT(1) FROM homeworks WHERE schedule_id = schedules.id) as homework_count, (SELECT COUNT(1) FROM homeworks WHERE schedule_id = schedules.id AND is_done = 1) as homework_done_count')
    .where("student_id = :student_id AND time + duration > :from_time #{end_time} #{mode}", {student_id: current_user.id, from_time: params[:start]})
    .group('schedules.id')
    .order('schedules.time ASC')    
    
    render layout: false
  end
  
  def show
    @homework = Schedule.find(params[:id])
    
    if @homework.student_id != current_user.id 
      render nothing: true and return
    end
    
    @tasks = @homework.homework.all  
    @comments = @homework.comment.order(id: :desc)  
    render layout: false
  end  
  
  def create
    schedule_id = params[:schedule_id]
    title = params[:title]
    text = params[:text]
    
    result = 0
    id = 0
    if schedule_id and not title.blank? and Schedule.exists?(schedule_id)
      schedule = Schedule.find(schedule_id)
      if schedule.student_id == current_user.id 
        homework = schedule.homework.new({ :title => title, :text => text, :by_student => 1 })
        if homework.save
          result = 1
          id = homework.id
        end
      end
    end
    
    render :json => { :result => result, :id => id }
  end
  
  def update
    homework = Homework.includes(:schedule).find(params[:id])       
    
    result = 0
    if params.has_key?(:title) && params.has_key?(:text)
      if homework.by_student
        title = params[:title]
        text = params[:text]
        
        if !title.blank? && (homework.schedule.student_id == current_user.id)
          if homework.update({ :title => title, :text => text }) 
            result = 1
          end 
        end        
      end      
    else  
      is_done = params[:done]
      if homework.schedule.student_id == current_user.id 
        if homework.update({ :is_done => is_done, :done_time => Time.now.to_i }) 
          result = 1
        end 
      end
    end
    
    render :json => { :result => result }     
  end
    
  def destroy
    homework = Homework.includes(:schedule).find(params[:id])
    
    result = 0    
    if homework.schedule.student_id == current_user.id and homework.by_student
      if homework.destroy    
        result = 1
      end 
    end
    
    render :json => { :result => result }    
  end
  
  def create_comment
    schedule_id = params[:schedule_id]
    text = params[:text]
    
    result = 0
    id = 0
    if schedule_id and not text.blank? and Schedule.exists?(schedule_id)
      schedule = Schedule.find(schedule_id)
      if schedule.student_id == current_user.id 
        comment = schedule.comment.new({ :text => text, :user_id => current_user.id })
        if comment.save
          result = 1
          id = comment.id
        end
      end
    end
    
    render :json => { :result => result, :id => id }    
  end
  
  def delete_comment
    comment_id = params[:comment_id]
    
    result = 0    
    if comment_id and current_user.comment.exists?(comment_id)
      comment = current_user.comment.find(comment_id)
      
      if comment.destroy
        result = 1
      end
    end
    
    render :json => { :result => result }    
  end
  
  def attach_file
    task_id = params[:task_id]
    
    result = 0
    id = 0
    
    if task_id and Homework.exists?(task_id)
      homework = Homework.find(task_id)
      
      if homework.schedule.student_id == current_user.id and not homework.schedule.elapsed?
        file = homework.homework_file.new(params.require(:homework_file).permit(:title, :file).merge({ :user_id => current_user.id }))
        if file.save
          result = 1
          id = file.id
        end
      end
    end
    
    render :json => { :result => result, :id => id }
  end
  
  def delete_file
    file_id = params[:file_id]
    
    result = 0    
    if file_id and HomeworkFile.exists?(file_id)
      homework_file = HomeworkFile.find(file_id)
      
      if homework_file.user_id == current_user.id and not homework_file.homework.schedule.elapsed?
        if homework_file.destroy
          result = 1
        end
      end
    end
    
    render :json => { :result => result }
  end
  
end
