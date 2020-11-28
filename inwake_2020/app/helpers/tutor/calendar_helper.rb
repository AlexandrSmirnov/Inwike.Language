module Tutor::CalendarHelper
  
  def tutor_timezone_list
    timezones = {}
    if current_user.time_zone.blank?
      timezones['local'] = 'System timezone'
    else
      timezones[ActiveSupport::TimeZone::MAPPING[current_user.time_zone]] = " #{ActiveSupport::TimeZone[current_user.time_zone]}"      
    end
    
    current_user.students.each do |student|
      if !student.time_zone.blank?
        next if !current_user.time_zone.blank? && student.time_zone == current_user.time_zone
        timezones[ActiveSupport::TimeZone::MAPPING[student.time_zone]] = "#{student.name}'s timezone #{ActiveSupport::TimeZone[student.time_zone]}"
      end
    end
        
    timezones
  end
  
  
end
