class Tutor::StatisticsController < ApplicationController
  force_ssl if Rails.env.production?
  before_filter :authenticate_user!
  layout "admin"
  
  def index
    @filter_params = statistics_filter_params || {}
    
    @filter_params[:start] ||= default_start
    @filter_params[:end] ||= default_end
    @filter_params[:time_interval] ||= "#{format_date(@filter_params[:start])} - #{format_date(@filter_params[:end])}"
    past_classes = Schedule.tutor(current_user.id).time_between(@filter_params[:start], @filter_params[:end]).assigned

    @classes = Schedule.classes_statistics(past_classes)
    @students = Schedule.includes(:student).select('*, COUNT(*) AS count').tutor(current_user.id).time_between(@filter_params[:start], @filter_params[:end]).assigned.past.group(:student_id)
    @schedules = Schedule.includes(:student).includes(:class_type).tutor(current_user.id).time_between(@filter_params[:start], @filter_params[:end]).assigned.past   
    @benefits = Schedule.payments_statistics(past_classes, current_user)
  end
    
  private
  def default_start
    now = Time.now.in_time_zone(Time.zone)
    now -= 1.month if now.strftime('%e').to_i == 1    
    now.beginning_of_month.to_i
  end
  
  def default_end
    Time.now.to_i
  end
  
  def format_date(timestamp)
    DateTime.strptime(timestamp.to_s, '%s').strftime('%Y-%d-%m')
  end
  
  def statistics_filter_params
    return nil if not params.has_key?(:filter)
    params.require(:filter).permit(:start, :end, :time_interval)
  end
  
end