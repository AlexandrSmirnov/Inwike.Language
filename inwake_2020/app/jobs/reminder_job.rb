class ReminderJob
 @queue = :simple

 def self.perform
    # За какое время до занятия приходит напоминание:   
  coming_lessons = Schedule.get_coming_lessons(3.hours + 1.minute)   
  coming_lessons.each do |lesson|    
    puts("#{Time.now} Отправляем уведомление о занятии #{lesson.id}. Время занятия #{DateTime.strptime(lesson.time.to_s, '%s')}. Преподаватель #{lesson.user_id}. Ученик #{lesson.student_id}")
    lesson.set_remind_time
    subject_text3 = "Урок через 3 часа"
    send_remind_mail(lesson.user_id, lesson, subject_text3) 
    send_remind_mail(lesson.student_id, lesson, subject_text3) 
  end
    # За какое время до занятия приходит напоминание:   
  coming_lessons_15min = Schedule.get_coming_lessons(15.minute)   
  coming_lessons_15min.each do |lesson|    
    puts("#{Time.now} Отправляем уведомление о занятии #{lesson.id}. Время занятия #{DateTime.strptime(lesson.time.to_s, '%s')}. Преподаватель #{lesson.user_id}. Ученик #{lesson.student_id}")
    lesson.set_remind_time
    subject_text15 = "Урок через 15 минут"
    send_remind_mail(lesson.user_id, lesson, subject_text15) 
    send_remind_mail(lesson.student_id, lesson, subject_text15) 
  end     
 end
 
  def self.send_remind_mail(user_id, lesson, subject_text)
    user = User.find(user_id)   
    if not user
      return
    end

    locale = user.locale.blank? ? I18n.default_locale : user.locale   
    about_payment = nil
    
    if user.time_zone.blank? 
      time_left = hours_minutes_left(lesson.time - Time.now.to_i, locale)   
      time_text = I18n.t('lesson_in_text', :time_left => time_left, :locale => locale)
    else
      time = DateTime.strptime(lesson.time.to_s, '%s').in_time_zone(user.time_zone).strftime('%H:%M') + " (#{user.time_zone})"
      time_text = I18n.t('lesson_at_text', :time => time, :locale => locale)
    end

    if user.has_role?(:tutor)
      message_text = I18n.t('nearest_lesson_tutor', :username => user.name, :student => lesson.student.name, :time => time_text, :about_payment => about_payment, :locale => locale)
    else   
      unless user.has_role?(:tutor) || lesson.free? || lesson.paid
        if lesson.deferred_payment?
          about_payment = I18n.t('nearest_deferred', :locale => locale)
        else
          about_payment = I18n.t('nearest_unpaid', :locale => locale)
        end
      end

      message_text = I18n.t('nearest_lesson', :username => user.name, :time => time_text, :about_payment => about_payment, :locale => locale)
    end  

    UserMailer.remind_email(user, message_text, subject_text).deliver   
  end
  
 def self.hours_minutes_left(time_left, locale)   
   hours_left = (time_left / 1.hour).ceil
   minutes_left = ((time_left - hours_left*1.hour) / 1.minute).ceil
   
   if hours_left
    "#{hours_left(hours_left, locale)} #{minutes_left(minutes_left, locale)}"
   else
     minutes_left(minutes_left, locale)
   end
 end
 
 def self.hours_left(hours_left, locale)
   if hours_left == 0
     return nil
   end
   
   hours_left_text = I18n.t('time_left.hours', :count => hours_left, :locale => locale) 
   "#{hours_left} #{hours_left_text}"
 end
 
 def self.minutes_left(minutes_left, locale)
   if minutes_left == 0
     return nil
   end
   
   minutes_left_text = I18n.t('time_left.minutes', :count => minutes_left, :locale => locale) 
   "#{minutes_left} #{minutes_left_text}"
 end
end