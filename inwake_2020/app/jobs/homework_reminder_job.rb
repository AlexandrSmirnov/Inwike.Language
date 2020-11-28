class HomeworkReminderJob
 @queue = :simple

 def self.perform  
  coming_homeworks = Schedule.get_coming_homeworks(24*60*60+60)   
  coming_homeworks.each do |lesson|   
    puts("#{Time.now} Отправляем уведомление о домашнем задании #{lesson.id}. Время сдачи #{DateTime.strptime(lesson.time.to_s, '%s')}. Преподаватель #{lesson.user_id}. Ученик #{lesson.student_id}")
    lesson.set_homework_remind_time
    send_homework_mail(lesson.student_id, lesson.time)
  end 
 end
 
 def self.send_homework_mail(user_id, time)
   user = User.find(user_id)   
   if not user
     return
   end
   
   hours_left = ((time - Time.now.to_i) / 1.hour).ceil
   locale = user.locale.blank? ? I18n.default_locale : user.locale
   
   time_left_text = I18n.t('time_left.hours', :count => hours_left, :locale => locale) 
   message_text = I18n.t('nearest_homework', :username => user.name, :time_left => "#{hours_left} #{time_left_text}", :locale => locale)   
   subject_text = "Домашнее задание"
   UserMailer.remind_email(user, message_text, subject_text).deliver   
 end
  
end
