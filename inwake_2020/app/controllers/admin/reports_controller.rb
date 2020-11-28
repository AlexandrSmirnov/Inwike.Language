class Admin::ReportsController < ApplicationController
  force_ssl if Rails.env.production?
  before_filter :authenticate_user!
  layout "admin"
  
  def index  
    @filter_params = {}
    @reports = Report.all.order('id DESC')
  end
  
  
  def show_report
    @filter_params = report_filter_params || {}
    
    @classes = nil
    @classes_all = nil
    @students = nil
    @schedules = nil
        
    if @filter_params.has_key?(:tutor_id) && @filter_params.has_key?(:start) && !@filter_params[:start].empty? && @filter_params.has_key?(:end) && !@filter_params[:end].empty? 
      
      if @filter_params[:tutor_id].empty? 
        @classes_sum = {
          :total => 0,
          :free => 0,
          :paid => 0,
          :not_paid => 0,
          :missed => 0,
          :missed_paid => 0
        }       
        @classes_all = Hash.new
        
        tutors = User.with_lessons_beetwen(report_filter_params[:start], report_filter_params[:end])
        tutors.each do |tutor|
          past_classes = Schedule.tutor(tutor.id).time_between(report_filter_params[:start], report_filter_params[:end]).assigned
          @classes_all[tutor.id] = Schedule.classes_statistics(past_classes).merge({:name => tutor.name})
          @classes_sum[:total] += @classes_all[tutor.id][:total]
          @classes_sum[:free] += @classes_all[tutor.id][:free]
          @classes_sum[:paid] += @classes_all[tutor.id][:paid]
          @classes_sum[:not_paid] += @classes_all[tutor.id][:not_paid]
          @classes_sum[:missed] += @classes_all[tutor.id][:missed]
          @classes_sum[:missed_paid] += @classes_all[tutor.id][:missed_paid]
        end
        
        @benefits_sum = {
          :payments => 0,
          :payments_due => 0,
          :fee => 0,
          :fee_for_transfer => 0,
          :income => 0
        }
        @benefits_all = Hash.new
        
        tutors.each do |tutor|
          past_classes = Schedule.tutor(tutor.id).time_between(report_filter_params[:start], report_filter_params[:end]).assigned   
          @benefits_all[tutor.id] = Schedule.payments_statistics(past_classes, tutor)
          @benefits_sum[:payments] += @benefits_all[tutor.id][:payments]
          @benefits_sum[:payments_due] += @benefits_all[tutor.id][:payments_due]
          @benefits_sum[:fee] += @benefits_all[tutor.id][:fee]
          @benefits_sum[:fee_for_transfer] += @benefits_all[tutor.id][:fee_for_transfer]
          @benefits_sum[:income] += @benefits_all[tutor.id][:income]
        end
        
      else
        tutor = User.find(@filter_params[:tutor_id])
        past_classes = Schedule.tutor(@filter_params[:tutor_id]).time_between(report_filter_params[:start], report_filter_params[:end]).assigned
        
        @classes = Schedule.classes_statistics(past_classes)
        @students = Schedule.includes(:student).select('*, COUNT(*) AS count').tutor(@filter_params[:tutor_id]).time_between(report_filter_params[:start], report_filter_params[:end]).assigned.past.group(:student_id)
        @schedules = Schedule.includes(:student).includes(:class_type).tutor(@filter_params[:tutor_id]).time_between(report_filter_params[:start], report_filter_params[:end]).assigned.past   
        @benefits = Schedule.payments_statistics(past_classes, tutor)
      end
    end      
  end
  
  
  def create
    classes_array = []
    classes_list = params['report']['classes']
    classes_list.each { |key, value| classes_array << key if value.to_i == 1} if params['report'].has_key? 'classes'
    tutor = User.find(params['report']['user_id'])
        
    classes = Schedule.find(classes_array)    
    benefits = Schedule.payments_statistics(classes, tutor)
    
    report = Report.new(report_params)
    report.classes_count = classes.count
    report.fee = benefits[:fee]
    report.fee_for_transfer = benefits[:fee_for_transfer] 
    report.save()
  
    Schedule.where(:id => classes_array).update_all(:report_id => report.id)
    
    redirect_to admin_reports_path    
  end
  
  
  def get_tutors_list
    start_time = params['start']
    end_time = params['end']
    
    tutors = User.with_lessons_beetwen(start_time, end_time)
    tutors_array = Hash.new    
      
    tutors.each do |tutor|     
      tutors_array[tutor.id] = tutor.name
    end
    render json: tutors_array
  end
  
  
  def set_as_executed
    @report = Report.find(params[:id])
    @report.update(:is_executed => true)
    
    redirect_to admin_reports_path
  end
  
  
  def destroy
    @report = Report.find(params[:id])    
    @report.destroy unless @report.is_executed
    
    redirect_to admin_reports_path
  end
  
  private
  def report_filter_params
    return nil if not params.has_key?(:filter)
    params.require(:filter).permit(:tutor_id, :start, :end, :time_interval)
  end
  def report_params
    return nil if not params.has_key?(:report)
    params.require(:report).permit(:user_id, :start, :end)
  end
end
