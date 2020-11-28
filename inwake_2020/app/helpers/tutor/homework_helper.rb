module Tutor::HomeworkHelper
  
  def time_left_text(time_left)   
    days_left = (time_left / 24.hour).ceil
    hours_left = ((time_left - days_left*24.hour)/ 1.hour).ceil
    
    if days_left.zero? && hours_left.zero?
      return I18n.t('time_left.less_than_hour')  
    end
    
    "#{days_left(days_left)} #{hours_left(hours_left)}"
  end
 
  def days_left(days_left)
    if days_left == 0
      return
    end
   
    days_left_text = I18n.t('time_left.days', :count => days_left) 
    "#{days_left} #{days_left_text}"
  end
 
  def hours_left(hours_left)
    if hours_left == 0
      return
    end
   
    hours_left_text = I18n.t('time_left.hours', :count => hours_left) 
    "#{hours_left} #{hours_left_text}"
  end
  
  
  
end
