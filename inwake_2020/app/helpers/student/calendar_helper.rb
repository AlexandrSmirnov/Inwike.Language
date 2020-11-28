module Student::CalendarHelper
  
  def student_timezone_list
    timezones = {}
    if current_user.time_zone.blank?
      timezones['local'] = 'System timezone'
    else
      timezones[ActiveSupport::TimeZone::MAPPING[current_user.time_zone]] = " #{ActiveSupport::TimeZone[current_user.time_zone]}"      
    end
    
    current_user.tutors.each do |tutor|
      if !tutor.time_zone.blank?
        next if !current_user.time_zone.blank? && tutor.time_zone == current_user.time_zone
        timezones[ActiveSupport::TimeZone::MAPPING[tutor.time_zone]] = "#{tutor.name}'s timezone #{ActiveSupport::TimeZone[tutor.time_zone]}"
      end
    end
        
    timezones
  end
  
end
