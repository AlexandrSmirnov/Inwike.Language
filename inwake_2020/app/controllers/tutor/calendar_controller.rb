class Tutor::CalendarController < ApplicationController
  force_ssl if Rails.env.production?
  before_filter :authenticate_user!
  layout "admin"
  
  def index
    @students_array = []    
    @lease_array = []    
    current_user.students.each do |student| 
      @students_array << ("#{student.id}: '#{student.name ? student.name : student.email}'")
      @lease_array << ("#{student.id}: #{student.lease ? true : false}")
    end
    @class_types = []
    current_user.class_type.each { |type| @class_types << "#{type.id}: '#{type.name}'" }
    
    @debtors = User.with_unpaided_lessons_with_tutor(current_user.id)
  end
  
  def list    
    if params[:start] and params[:end]
      start_time = Date.strptime(params[:start], "%Y-%m-%d").to_time.to_i
      end_time = Date.strptime(params[:end], "%Y-%m-%d").to_time.to_i
      @schedule_list = current_user.schedule.includes(:student).includes(:payment)
        .select('*, (SELECT COUNT(1) FROM homeworks WHERE schedule_id = schedules.id) as homework_count, (SELECT COUNT(1) FROM homeworks WHERE schedule_id = schedules.id AND is_done = 1) as homework_done_count')
        .where("time >= :start AND time <= :end", {start: start_time, end: end_time})
    else
      @schedule_list = current_user.schedule.includes(:student).includes(:payment)      
        .select('*, (SELECT COUNT(1) FROM homeworks WHERE schedule_id = schedules.id) as homework_count, (SELECT COUNT(1) FROM homeworks WHERE schedule_id = schedules.id AND is_done = 1) as homework_done_count')
        .all  
    end
    schedule_array = Array.new
    
    timezone = params[:timezone] || 'UTC'
    
    @schedule_list.each do |schedule|
      homework_tasks = Array.new 
      
      if params[:start] and params[:end]
        schedule.homework.all.each do |task|
          homework_tasks << {"title" => task.title, "is_done" => task.is_done}
        end
      end
      
      if schedule.student_id
        if schedule.student.name
          title = schedule.student.name
        else 
          title = schedule.student.email
        end        
        studentId = schedule.student.id    
      else
        title = t('calendar.free_time')
        studentId = nil
      end
    
      schedule_array << { 
          "title" => title, 
          "id" => schedule.id, 
          "start" => Time.at(schedule.time).to_datetime.in_time_zone(timezone), 
          "duration" => schedule.duration, 
          "end" => Time.at(schedule.time + schedule.duration).to_datetime.in_time_zone(timezone),
          "className" => schedule.class_name, 
          "studentId" => studentId, 
          "paid" => (schedule.student_id? && schedule.student.lease && schedule.lease_paid) ? true : schedule.paid, 
          "deferred_payment" => schedule.deferred_payment, 
          "free" => schedule.free, 
          "editable" => !schedule.elapsed?,
          "icon" => schedule.homework_icon,
          "icon2" => (schedule.assigned? && schedule.elapsed? && schedule.carried_out? && !schedule.free && !schedule.paid) ? 'fa-thumbs-down' : '' ,
          "homework_tasks" => homework_tasks,
          "class_type" => schedule.class_type_id,
          "lease" => schedule.student_id? ? schedule.student.lease : false,
          "carried_out" => schedule.carried_out?,
          "group" => schedule.group, 
          "allDay" => ""         
        }
    end
    
    render json: schedule_array
  end
  
  def create
    @schedule = current_user.schedule.new(schedules_param)    
    
    result = 0
    if !(params[:student_id]) || (params[:student_id] && (current_user.student_user.find(params[:student_id])))    
      if @schedule.save  
        result = 1
        
        if schedules_param.has_key?(:student_id) && schedules_param[:student_id].to_i.nonzero?
          move_undone_homework(schedules_param[:student_id])
        end        
      end 
    end
    
    render :json => { :result => result, :id => @schedule.id }
  end
  
  def update
    @schedule = Schedule.find(params[:id])
    
    result = 0    
    if @schedule.elapsed?   
      if params.require(:schedule).has_key?(:carried_out) #&& @schedule.student.lease    
        result = 1
        @schedule.state = params[:schedule][:carried_out] ? 9 : 10                 
        @schedule.save
      end
    else
      if !(params[:student_id]) || (params[:student_id] && (current_user.student_user.find(params[:student_id])))
        if (@schedule.user == current_user) && @schedule.update(schedules_param)      
          result = 1
          @schedule.reset_state                   
          @schedule.save
          if schedules_param.has_key?(:student_id) && schedules_param[:student_id].to_i.nonzero?
            move_undone_homework(schedules_param[:student_id])
          end      
        end      
      end    
    end
    
    render :json => { :result => result }    
  end
  
  def destroy
    @schedule = Schedule.find(params[:id])
    
    result = 0    
    if (@schedule.user == current_user) && !@schedule.elapsed? && @schedule.destroy    
      result = 1
    end 
    
    render :json => { :result => result }    
  end
  
  private
  def move_undone_homework(student_id)
    student = User.find(student_id)
    student.actualize_homework_with_tutor(current_user.id)
  end
  
  private
  def schedules_param
    params.require(:schedule).permit(:time, :offset, :duration, :student_id, :deferred_payment, :free, :lease_paid, :class_type_id, :group)    
  end
  
end
