class TutorTimeZone < ActiveSupport::TimeZone
  
  def self.all
    timezones = Tutor.get_timezones
    timezones_hash = zones_map.select {|key, value| timezones.include? key} 
    timezones_hash.values.sort 
  end
  
  def to_s
    name = self.name.gsub(/\(.*\)/, '')  
    "GMT#{formatted_offset}<br/> <span>#{name}</span>"
  end
      
end