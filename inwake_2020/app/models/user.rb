class User < ActiveRecord::Base
  
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable     
              
  ROLES = %w[admin tutor student]
  LOCALES = %w[ru en]
  
  def roles=(roles)
    self.roles_mask = (roles & ROLES).map { |r| 2**ROLES.index(r) }.inject(0, :+)
  end

  def roles
    ROLES.reject do |r|
      ((roles_mask.to_i || 0) & 2**ROLES.index(r)).zero?
    end
  end
  
  def has_role?(role)
    roles.include?(role.to_s)
  end
  
  has_many :schedule  
  has_many :student_schedule, class_name: "Schedule", foreign_key: "student_id" 
                            
  has_many :sent_messages, class_name: "ChatMessage", foreign_key: "sender_id" 
  has_many :received_messages, class_name: "ChatMessage", foreign_key: "recipient_id" 
 
  has_many :student_tutor_links, :class_name => "TutorStudent", :foreign_key => "student_id"
  has_many :tutors, :through => :student_tutor_links
  has_many :tutor_student_links, :class_name => "TutorStudent", :foreign_key => "tutor_id"
  has_many :students, :through => :tutor_student_links
  
  has_many :class_type, :through => :tutor_classes
  has_many :tutor_classes  
                          
  has_many :payment
  has_many :comment
  has_many :homework_file    
  has_many :error_report
  has_many :report
  

  scope :role_filter, (lambda do |filter| 
    return if not filter or not filter.include?('role') or filter['role'].length.zero?
    where(["(roles_mask & ?) > 0", 1 << filter['role'].to_i])    
  end)

  scope :debts_filter, (lambda do |filter| 
    return if not filter or not filter.include?('with_debts') or filter['with_debts'].length.zero?
    where("(SELECT COUNT(*) FROM schedules LEFT JOIN payments ON schedules.payment_id = payments.id WHERE (schedules.student_id = users.id OR schedules.user_id = users.id) AND state = 9 AND (pay_time IS NULL OR pay_time = 0) AND (free IS NULL OR free = 0)) > 0")
  end)
  
  scope :name_filter, (lambda do |filter| 
    return if not filter or not filter.include?('name') or filter['name'].length.zero?
    where(["name LIKE ?", "%#{filter['name']}%"])
  end)
    
  scope :with_role, lambda {|role| {:conditions => "(roles_mask & #{1 << ROLES.index(role)}) > 0"}}  
  scope :with_unpaided_lessons, (lambda do
      where("(SELECT COUNT(*) FROM schedules
                LEFT JOIN payments ON schedules.payment_id = payments.id
                WHERE schedules.student_id = users.id AND
                (pay_time IS NULL OR pay_time = 0) AND (free IS NULL OR free = 0) AND 
                state = 9) > 0")
  end)
  scope :with_unpaided_lessons_with_tutor, (lambda do |tutor_id| 
      where(["(SELECT COUNT(*) FROM schedules
                LEFT JOIN payments ON schedules.payment_id = payments.id
                WHERE schedules.student_id = users.id AND
                schedules.user_id = ? AND
                (pay_time IS NULL OR pay_time = 0) AND (free IS NULL OR free = 0) AND 
                state = 9) > 0", tutor_id])
  end)

  scope :with_unpaided_without_notification, (lambda do |time| 
      where(["(SELECT COUNT(*) FROM schedules
                LEFT JOIN payments ON schedules.payment_id = payments.id
                WHERE schedules.student_id = users.id AND
                schedules.time < ? AND
                (pay_time IS NULL OR pay_time = 0) AND (free IS NULL OR free = 0) AND 
                payment_remind_time IS NULL AND 
                state = 9) > 0", time])
  end)

  scope :with_lessons_beetwen, (lambda do |start_time, end_time| where(["(SELECT COUNT(*) FROM schedules WHERE user_id = users.id AND? < time AND time < ?) > 0", start_time, end_time]) end)
     
    
  PerPage = 10
  def self.page(page, sort = {})
    field = 'id'
    order = 'asc'
    
    if sort['field'] && sort['order']
      if (%w[id name]).include?(sort['field'].downcase)
        field = sort['field']
      end  
      if sort['order'].downcase == 'asc' || sort['order'].downcase == 'desc'
        order = sort['order']
      end  
    end
    
    return self.order("users.#{field} #{order}").offset((page.to_i-1) * PerPage).limit(PerPage)
  end
 
  def self.pages_count
    return count % PerPage == 0 ? count / PerPage : count / PerPage + 1
  end
    
  def get_user_data_as_json
    JSON.generate({
      "id" => self.id, 
      "email" => self.email, 
      "role" => if self.has_role? :tutor then 'tutor' elsif self.has_role? :student then 'student' else '' end, 
    })
  end
  
  def get_chat_users
    chat_users = {}
    if self.has_role? :tutor
      self.all_students.each { |student| chat_users[student.id] = student.name }
    end     
    if self.has_role? :student
      self.all_tutors.each { |tutor| chat_users[tutor.id] = tutor.name }
    end    
    chat_users
  end
  
  def update(params)
    class_type_costs = nil
    class_type_fees = nil
    
    if params.include?('class_type_list')
      if params.include?('class_type_costs')
        class_type_costs = Hash[params[:class_type_list].zip params[:class_type_costs]]
        params.delete :class_type_costs
      end      
      
      if params.include?('class_type_fees')
        class_type_fees = Hash[params[:class_type_list].zip params[:class_type_fees]]
        params.delete :class_type_fees
      end      
      params.delete :class_type_list
    end
    
    super(params)
    update_fees_and_costs(class_type_fees, class_type_costs)
  end
  
  def update_fees_and_costs(class_type_fees, class_type_costs)    
    self.tutor_classes.each do |tutor_class|
      tutor_class.update({:fee => class_type_fees[tutor_class.class_type_id.to_s]}) if class_type_fees && class_type_fees.include?(tutor_class.class_type_id.to_s)
      tutor_class.update({:cost => class_type_costs[tutor_class.class_type_id.to_s]}) if class_type_costs && class_type_costs.include?(tutor_class.class_type_id.to_s)
    end
    
    true
  end
  
  # Функция возвращает время ближайшего занятия
  def get_nearest_lesson
    if self.has_role?('tutor')
      return self.get_tutor_nearest_lesson 
    elsif self.has_role?('student')
      return self.get_student_nearest_lesson      
    end   
    
    return nil
  end
    
  # Функция возвращает время ближайшего занятия для ученика
  def get_student_nearest_lesson
    nearest_lessons = Schedule
                        .eager_load(:payment)
                        .where("time + duration > :end_time AND student_id = :student_id AND (pay_time OR free OR deferred_payment OR lease_paid)", {end_time: Time.now.to_i - Rails.configuration.lesson_time_limit, student_id: self.id})
                        .order(time: :asc)
                        .limit(1)

    if (nearest_lessons.count == 1)
      nearest_lesson = nearest_lessons[0].time
      tutor = nearest_lessons[0].user_id
      student = self.id
      duration = nearest_lessons[0].duration
      id = nearest_lessons[0].id
      group = nearest_lessons[0].group
      if nearest_lesson - Rails.configuration.lesson_time_limit < Time.now.to_i
        enabled = true
      else
        enabled = false
      end
    else
      nearest_lesson = 0
      tutor = 0
      student = 0
      duration = 0
      id = 0
      enabled = false
    end
    
    {"time" => nearest_lesson, "duration" => duration, "tutor" => tutor, "student" => student, "id" => id, "enabled" => enabled, "group" => group}
  end
    
  # Функция возвращает время ближайшего занятия для преподавателя
  def get_tutor_nearest_lesson
    nearest_lessons = self.schedule
                        .eager_load(:payment)
                        .where("time + duration > :end_time AND student_id > 0 AND (pay_time OR free OR deferred_payment OR lease_paid)", {end_time: Time.now.to_i - Rails.configuration.lesson_time_limit})
                        .order(time: :asc)
                        .limit(2)
    
    overlapping = {}
    if (nearest_lessons.count > 0)
      nearest_lesson = nearest_lessons[0].time    
      tutor = self.id     
      student_id = nearest_lessons[0].student_id   
      student = User.find(student_id)
      student_email = student.email
      duration = nearest_lessons[0].duration 
      id = nearest_lessons[0].id 
      group = nearest_lessons[0].group
      if (student.name)
        student_name = student.name
      else
        student_name = student.email
      end
      
      if nearest_lessons.count == 2 and Time.now.to_i > nearest_lessons[1].time - Rails.configuration.lesson_time_limit
        overlap_student_id = nearest_lessons[1].student_id   
        overlap_student = User.find(overlap_student_id)
        if (overlap_student.name)
          overlap_student_name = overlap_student.name
        else
          overlap_student_name = overlap_student.email
        end
        overlapping = {"time" => nearest_lessons[1].time, "duration" => nearest_lessons[1].duration, "student" => overlap_student_id, "name" => overlap_student_name, "email" => overlap_student.email, "opentok_id" => overlap_student.opentok_id, "id" => nearest_lessons[1].id, "enabled" => true, "group" => group}
      end
    
      if nearest_lesson - Rails.configuration.lesson_time_limit < Time.now.to_i
        enabled = true
      else
        enabled = false
      end
      
    else
      nearest_lesson = 0
      tutor = 0
      student_id = 0
      student_name = ''
      student_email = ''
      student_opentok_id = ''
      duration = 0
      id = 0
      enabled = false
    end
    
    {"time" => nearest_lesson, "duration" => duration, "tutor" => tutor, "student" => student_id, "name" => student_name, "email" => student_email, "opentok_id" => student_opentok_id, "overlapping" => overlapping, "id" => id, "enabled" => enabled, "group" => group}
  end
  
  def send_nearest_lesson
    puts 'send_nearest_lesson'
    nearest_lesson = self.get_nearest_lesson
    WebsocketRails.users[self.id].send_message('nearest_lesson', nearest_lesson)     
  end
  
  def online?
    return WebsocketRails.users[self.id].is_a?(WebsocketRails::UserManager::LocalConnection)
    false
  end
  
  # Функция возвращает последнее запланированное занятие (состоявшееся или несостоявшееся)
  def get_last_lesson
    prev_lessons = nil
    
    if self.has_role?('tutor')
      prev_lessons = Schedule.where("time < :time AND student_id = :user_id", {time: Time.now.to_i, user_id: self.id}).order(time: :desc).limit(1)
    elsif self.has_role?('student')
      prev_lessons = Schedule.where("time < :time AND user_id = :user_id", {time: Time.now.to_i, user_id: self.id}).order(time: :desc).limit(1)
    end   
    
    return prev_lessons.first if prev_lessons && (prev_lessons.count == 1)    
    nil
  end
  
  
  # Функция возвращает последнее запланированное занятие (состоявшееся или несостоявшееся) с определенным преподавателем
  def get_last_lesson_with_tutor(tutor_id)
    last_lesson = Schedule.where("time < :time AND student_id = :student_id AND user_id = :tutor_id", {time: Time.now.to_i, student_id: self.id, tutor_id: tutor_id}).order(time: :desc).limit(1)
    
    return last_lesson.first if (last_lesson.count == 1)
    nil    
  end
  
  
  # Функция возвращает ближайшее занятие с определенным преподавателем
  def get_next_lesson_with_tutor(tutor_id)  
    next_lessons = Schedule.where("time > :time AND student_id = :student_id AND user_id = :tutor_id", {time: Time.now.to_i, student_id: self.id, tutor_id: tutor_id}).order(time: :asc).limit(1)
    
    return next_lessons.first if (next_lessons.count == 1)
    nil
  end
    
  # Функция копирует невыполненные пункты ДЗ с последнего занятия на следующее (если оно существует) с определенным преподавателем 
  def actualize_homework_with_tutor(tutor_id)
    return unless self.has_role?('student')
    
    last_lesson = self.get_last_lesson_with_tutor(tutor_id)
    return unless last_lesson    
    return unless last_lesson.has_undone_homework?
    
    next_lesson = self.get_next_lesson_with_tutor(tutor_id)
    return unless next_lesson

    last_lesson.move_undone_homework_to_schedule(next_lesson)
  end
  
  
  # Функция возвращает true, если у преподавателя есть активные занятия с указанным учеником
  def has_active_lesson_with_student? (student_id)
    active_lesson_count = self.schedule
                              .where("time < :start_time AND time + duration > :end_time AND student_id = :student_id", {start_time: Time.now.to_i + Rails.configuration.lesson_time_limit, end_time: Time.now.to_i - Rails.configuration.lesson_time_limit, student_id: student_id})
                              .count
                              
    if active_lesson_count == 0
      return false      
    end
    return true
  end
  
  # Отправляет уведомление о входящем сообщении в случае необходимости
  def notify_about_message (message)
    if self.last_message_notification and self.last_message_notification > Time.now.to_i - Rails.configuration.message_notification_interval
      return
    end
    self.set_last_message_notification(Time.now.to_i)
        
    locale = self.locale || I18n.default_locale
    
    sender = User.find(message['sender'])
    if sender.has_role?('tutor')
      user_status_text = I18n.t('general.tutor', :locale => locale)
    elsif sender.has_role?('student')   
      user_status_text = I18n.t('general.student', :locale => locale)
    else
      user_status_text = I18n.t('general.user', :locale => locale)
    end
    
    message_text = I18n.t('notify_about_message', :username => self.name, :user_status => user_status_text, :another_user => sender.name, :message => message['message'], :locale => locale)   
    message_subject = I18n.t('notify_about_message_title', :locale => locale) 
    UserMailer.remind_email(self, message_text, message_subject).deliver    
    
    puts("#{Time.now} Отправляем пользователю #{self.id} (#{self.email}) уведомление о сообщении")
  end
  
  # Функция устанавливает время последнего оповещения об отправленном сообщении
  def set_last_message_notification(time)
    self.update({:last_message_notification => time})    
  end
    
  def self.send_notification_to_admins(message, subject = 'lang')
    User.with_role('admin').each do |admin|
      UserMailer.remind_email(admin, message, subject).deliver    
    end
  end
  
  def all_students
    self.students.where("(roles_mask & 4) > 0")
  end
  
  def all_tutors
    self.tutors.where("(roles_mask & 2) > 0")
  end
  
  def self.register_from_request(request)
    return if request.name.blank? || request.email.blank?
    if User.exists?(email: request.email)
      UserMailer.new_user(request.name, request.email, request.phone, nil).deliver
    else
      password = Devise.friendly_token.first(8)   
      roles = Rails.configuration.project == 'my' ? ['tutor'] : ['student']
      user = User.new({:name => request.name, :email => request.email, :roles => roles, :password => password})     
      if user.save
        UserMailer.new_user(user.name, user.email, request.phone, password).deliver
      end
    end
  end
  
  def fee_for_transfer(fee)
    return fee * (1 + self.transfer_fee/100) if self.transfer_fee? 
    fee
  end
  
  def payment_allowed?
    return true unless (Rails.configuration.project == 'my') || self.lease
    (Rails.configuration.project == 'my') && !self.tutors.length.zero? && !self.tutors.first.lease_ymoney_account.blank?
  end
   
end
