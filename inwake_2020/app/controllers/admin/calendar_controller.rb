class Admin::CalendarController < ApplicationController
  force_ssl if Rails.env.production?
  before_filter :authenticate_user!
  layout "admin"
  
  def index
    @class_types = []
    @tutors = []
    ClassType.all.each { |type| @class_types << "#{type.id}: '#{type.name}'" }
    User.with_role('tutor').each { |tutor| @tutors << "#{tutor.id}: '#{tutor.name}'" }
  end
  
  
  def list            
    if params[:start] and params[:end]
      start_time = Date.strptime(params[:start], "%Y-%m-%d").to_time.to_i
      end_time = Date.strptime(params[:end], "%Y-%m-%d").to_time.to_i
      @schedule_list = Schedule.where("time >= :start_time AND time <= :end_time AND student_id IS NOT NULL", {start_time: start_time, end_time: end_time}).includes(:payment).includes(:user).includes(:student)
    else
      @schedule_list = Schedule.includes(:payment)
    end
    schedule_array = Array.new    
      
    @schedule_list.each do |schedule|     
      student_name = schedule.student ? schedule.student.name : ''
      tutor_name = schedule.user ? schedule.user.name : ''
      schedule_array << { 
          "title" => "#{tutor_name} - #{student_name}", 
          "tutor" => tutor_name,
          "user_id" => schedule.user.id,
          "student" => student_name,
          "id" => schedule.id, 
          "start" => Time.at(schedule.time).to_datetime.utc, 
          "duration" => schedule.duration, 
          "end" => Time.at(schedule.time + schedule.duration).to_datetime.utc,
          "className" => schedule.class_name, 
          "paid" => schedule.paid, 
          "deferred_payment" => schedule.deferred_payment, 
          "free" => schedule.free, 
          "editable" => false,
          "icon2" => (schedule.assigned? && schedule.elapsed? && schedule.carried_out? && !schedule.free && !schedule.paid) ? 'fa-thumbs-down' : '' ,
          "real_start" => schedule.start_time,
          "real_end" => schedule.end_time,
          "real_duration" => schedule.real_duration,
          "class_type" => schedule.class_type_id,
          "cost" => schedule.cost,
          "saved_cost" => schedule.saved_cost,
          "allDay" => ""         
        }
    end
    
    render json: schedule_array
  end
  
  
  def update
    @schedule = Schedule.find(params[:id])
    
    result = 0    
    if @schedule.update(schedules_param)      
      result = 1
    end 
    
    render :json => { :result => result }    
  end
  
  
  private
  def schedules_param
    params.require(:schedule).permit(:deferred_payment, :free, :class_type_id, :user_id, :saved_cost)    
  end
    
end
