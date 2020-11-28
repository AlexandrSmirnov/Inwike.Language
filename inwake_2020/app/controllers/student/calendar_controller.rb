class Student::CalendarController < ApplicationController
  force_ssl if Rails.env.production?
  before_filter :authenticate_user!
  layout "admin"
  
  def index
    begining_of_week = Time.now.beginning_of_week - (1 - t('datetime.calendar.first_week_day'))    
  end
  
  
  def vacant    
    if params[:start] and params[:end]
      @schedule_list = Schedule.where("(student_id IS NULL OR student_id = :student_id) AND time >= :start_time AND time <= :end_time AND time + duration > :current_time AND user_id IN (:tutors)", {start_time: params[:start], end_time: params[:end], student_id: current_user.id, current_time: Time.now.to_i, tutors: current_user.tutors.pluck('users.id')})
    else
      @schedule_list = Schedule.where("student_id IS NULL OR student_id = :student_id AND time + duration > :current_time AND user_id IN (:tutors)", {student_id: current_user.id, current_time: Time.now.to_i, tutors: current_user.tutor_ids})   
    end
    
    vacant_array = Array.new
    
    @schedule_list.each do |schedule|
      vacant_array << { "start" => schedule.time, "duration" => schedule.duration, "id" => schedule.id }    
    end
    
    render json: vacant_array
  end
  

  def update
    @schedule = Schedule.find(params[:id])
        
    result = 0 
    unless @schedule.elapsed?
      if current_user.tutor_ids.include?(@schedule.user_id)
        if @schedule.update_attribute(:student_id, current_user.id)
          current_user.actualize_homework_with_tutor(@schedule.user_id)
          result = 1
        end
      end
    end
    
    render :json => { :result => result }         
  end
  
  
  def destroy
    @schedule = Schedule.find(params[:id])
    
    result = 0    
    if (@schedule.student == current_user) && !@schedule.elapsed? && @schedule.update_attributes({student_id: nil, free: nil, deferred_payment: nil}) 
      result = 1
    end     
    render :json => { :result => result }    
  end
  
  def list            
    if params[:start] and params[:end]
      start_time = Date.strptime(params[:start], "%Y-%m-%d").to_time.to_i
      end_time = Date.strptime(params[:end], "%Y-%m-%d").to_time.to_i
      @schedule_list = Schedule
        .select('*, (SELECT COUNT(1) FROM homeworks WHERE schedule_id = schedules.id) as homework_count, (SELECT COUNT(1) FROM homeworks WHERE schedule_id = schedules.id AND is_done = 1) as homework_done_count')
        .where("time >= :start_time AND time <= :end_time AND student_id = :student_id", {start_time: start_time, end_time: end_time, student_id: current_user.id}).includes(:payment)
    else
      @schedule_list = Schedule
        .select('*, (SELECT COUNT(1) FROM homeworks WHERE schedule_id = schedules.id) as homework_count, (SELECT COUNT(1) FROM homeworks WHERE schedule_id = schedules.id AND is_done = 1) as homework_done_count')
        .where("student_id = :student_id", {student_id: current_user.id}).includes(:payment)
    end
    schedule_array = Array.new    
  
    timezone = params[:timezone] || 'UTC'
    
    @schedule_list.each do |schedule|     
      homework_tasks = Array.new 
      
      if params[:start] and params[:end]
        schedule.homework.each do |task|
          homework_tasks << {"title" => task.title, "is_done" => task.is_done}
        end
      end
      
      schedule_array << { 
          "title" => "Занятие", 
          "id" => schedule.id, 
          "start" => Time.at(schedule.time).to_datetime.in_time_zone(timezone), 
          "duration" => schedule.duration, 
          "end" => Time.at(schedule.time + schedule.duration).to_datetime.in_time_zone(timezone),
          "className" => schedule.class_name, 
          "paid" => schedule.paid, 
          "deferred_payment" => schedule.deferred_payment, 
          "free" => schedule.free, 
          "editable" => !schedule.elapsed?,
          "icon" => schedule.homework_icon,
          "homework_tasks" => homework_tasks,
          "lease" => current_user.lease || my?,
          "lease_payment_enabled" => current_user.payment_allowed?,
          "cost" => schedule.cost,
          "allDay" => ""
        }
    end
    
    render json: schedule_array
  end
  
end
