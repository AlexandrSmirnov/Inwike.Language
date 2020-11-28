class NearestLessonJob
 @queue = :simple

  def self.perform  
    # Обновляем состояния занятий
    set_states 

    # Получаем занятия, которые закончились недавно
    Schedule.where("state = 8").each do |lesson|   
      next unless lesson.finished?
      set_lesson_real_duration(lesson)
      lesson.actualize_homework
      lesson.save_cost
    end         

    # Получаем занятия, которые закончились только что, либо должны закончиться через lesson_time_limit
    Schedule.where("state IN (1, 4, 6)").each do |lesson|     
      send_nearest_lesson(lesson.user_id) if lesson.user_id?
      send_nearest_lesson(lesson.student_id) if lesson.student_id?
      lesson.increase_state
    end
  end
  
  def self.send_nearest_lesson(user_id)
    User.find(user_id).send_nearest_lesson
  end
 
  def self.set_states
    Schedule.update_all( "state = 1", "state IS NULL AND time <= #{Time.now.to_i + Rails.configuration.lesson_time_limit}" )
    Schedule.update_all( "state = 3", "state < 3 AND time <= #{Time.now.to_i}" )
    Schedule.update_all( "state = 4", "state < 4 AND time + duration <= #{Time.now.to_i + Rails.configuration.lesson_time_limit}" )
    Schedule.update_all( "state = 6", "state < 6 AND time + duration <= #{Time.now.to_i}" )
    Schedule.update_all( "state = 8", "state < 8 AND time + duration <= #{Time.now.to_i - Rails.configuration.lesson_time_limit}" )
  end
 
  # Получаем фактическую продолжительность занятия, а также время начала и конца занятия
  def self.set_lesson_real_duration(lesson)     
    return unless $redis.hlen("langLesson:#{lesson.id}")

    timestamp_array = $redis.hgetall("langLesson:#{lesson.id}") 
    
    start_time = get_start_time(timestamp_array)
    end_time = get_end_time(timestamp_array)
    duration = get_real_duration(timestamp_array)

    lesson.set_real_duration(start_time, end_time, duration)
    if start_time.zero? && end_time.zero? && duration.zero?
      lesson.set_state(10)
    else
      lesson.set_state(9)
    end
  end
  

  # Функция возвращает время начала занятия
  def self.get_start_time(timestamp_array)
    timestamp_array.each do |time, type| 
      return (time.to_i/1000).ceil if type == 'start'      
    end   
    return 0
  end
 
 
  # Функция возвращает время конца занятия
  def self.get_end_time(timestamp_array)
    end_time = 0
    timestamp_array.each do |time, type| 
      end_time = time.to_i if type == 'stop'      
    end   
    return (end_time/1000).ceil
  end
 
 
 # Функция возвращает фактическую продолжительность занятия
 def self.get_real_duration(timestamp_array)   
   last_start_time = 0
   duration = 0
   
   timestamp_array.each do |time, type| 
     if type == 'start'     
       if last_start_time == 0
         last_start_time = time.to_i
       end       
     end
     
     if type == 'stop'    
       if last_start_time
         duration += time.to_i - last_start_time
         last_start_time = 0
       end                    
     end     
   end 
   
   return (duration/1000).ceil
 end
 
 
end