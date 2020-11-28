class Schedule < ActiveRecord::Base  
  has_many :homework
  has_many :comment
  belongs_to :user
  belongs_to :student, class_name: "User"
  belongs_to :payment
  belongs_to :class_type  
  belongs_to :report
  
  scope :assigned, -> { where("student_id IS NOT NULL") }
  scope :tutor, (lambda do |tutor_id| where(["schedules.user_id = ?", tutor_id]) end)
  
  scope :free, -> { where("free = 1") }
  scope :paid, -> { eager_load(:payment).where("pay_time IS NOT NULL") }
  scope :not_paid, -> { eager_load(:payment).where("(pay_time IS NULL OR pay_time = 0) AND (free IS NULL OR free = 0)") }
  scope :for_paid, -> { eager_load(:payment).where("(state = 9 AND (pay_time IS NULL OR pay_time = 0)) OR ((state < 9 OR state IS NULL) AND (free IS NULL OR free = 0))") }
  
  scope :time_between, (lambda do |start_time, end_time| where(["? < time AND time < ?", start_time, end_time]) end)
  scope :missed, -> { where("state = 10") }
  scope :carried_out, -> { where("state = 9") }
  scope :past, -> { where("state IN (9, 10)") }
  
  after_create { |schedule| schedule.message_to_rt 'create' }
  after_update { |schedule| schedule.message_to_rt 'update' }
  after_destroy { |schedule| schedule.message_to_rt 'destroy' }
  
  def message_to_rt(action)    
    tutor_nearest_lesson = User.find(self.user_id).get_tutor_nearest_lesson
    WebsocketRails.users[self.user_id].send_message('nearest_lesson', tutor_nearest_lesson) 
    
    if self.student_id
      student_nearest_lesson = User.find(self.student_id).get_student_nearest_lesson
      WebsocketRails.users[self.student_id].send_message('nearest_lesson', student_nearest_lesson)     
    end
  end
  
  def class_name
    if not self.student_id
      return "vacant"
    end
    if self.elapsed?
      if self.carried_out?
        return "elapsed"
      else
        return "missed"
      end
    end
    if self.student && self.student.lease && self.lease_paid
      return "paid"
    end
    if self.payment && self.payment.pay_time 
      return "paid"
    end
    if self.free
      return "free"
    end
    if self.deferred_payment
      return "deferred_payment"
    end
    
    return "occupied" 
  end
  
  def report_label
    if self.carried_out?
      return '<span class="label label-info">Бесплатное</span>' if self.free?
      return '<span class="label label-success">Оплачено</span>' if self.paid
      return '<span class="label label-danger">Не оплачено</span>' if !self.paid
    end    
    
    return '<span class="label label-default">Не состоялось</span> <span class="label label-default">Бесплатное</span>' if self.free?
    return '<span class="label label-default">Не состоялось</span> <span class="label label-warning">Оплачено</span>' if self.paid
    return '<span class="label label-default">Не состоялось</span> <span class="label label-default">Не оплачено</span>' if !self.paid
    
    return ''
  end
  
  def homework_icon
    if self.homework_count == 0
      #return "fa-circle-o"
      return ""
    end    
    if self.homework_done_count == self.homework_count
      return "fa-check"
    end
    if self.elapsed?
      return "fa-ban"
    end
    
    return "fa-exclamation"    
  end
  
  def homework_class
    if self.homework_done_count == self.homework_count and self.homework_count != 0
      return "success"
    end
    if self.in_progress?
      return "danger"
    end
    if self.warning_time?
      return "warning"      
    end
    
    return "default"    
  end
  
  def homework_tip
    if self.homework_count == 0
      return 'homework.nothing_is_set'
    end      
    if self.homework_done_count == self.homework_count
      return 'homework.all_done'
    end
    
    return 'homework.not_perform'
  end
  
  def warning_time?
    if 0 < self.time - Time.now.to_i and self.time - Time.now.to_i < 12.hour
      return true
    end    
    return false
  end
  
  def homework_progress
    if self.homework_count == 0
      return 0
    end    
    if self.homework_count == self.homework_done_count
      return 100
    end    
    return (100 * self.homework_done_count / self.homework_count).to_i
  end
  
  def paid
    if self.payment and self.payment.pay_time  
      return true
    end
    return false
  end
  
  def elapsed?
    if self.time + self.duration + Rails.configuration.lesson_time_limit < Time.now.to_i 
      return true
    end
    return false
  end
  
  def in_progress?
    if self.time - Rails.configuration.lesson_time_limit < Time.now.to_i and Time.now.to_i < self.time + self.duration + Rails.configuration.lesson_time_limit
      return true
    end
    return false    
  end  
  
  def carried_out?
    return true if self.state == 9
    false
  end
  
  def assigned?
    return true if self.student_id
    false
  end
  
  def cost           
    return self.saved_cost if self.saved_cost?
    
    if self.class_type
      if self.student && self.student.class_type.exists?(self.class_type)
        tutor_class_types = TutorClass.find_all_by_user_id_and_class_type_id(self.student_id, self.class_type_id)        
        if tutor_class_types.count.nonzero? && tutor_class_types.first.cost && tutor_class_types.first.cost.nonzero?
          return tutor_class_types.first.cost
        end        
      end
      
      if self.user && self.user.class_type.exists?(self.class_type)
        tutor_class_types = TutorClass.find_all_by_user_id_and_class_type_id(self.user_id, self.class_type_id)        
        if tutor_class_types.count.nonzero? && tutor_class_types.first.cost && tutor_class_types.first.cost.nonzero?
          return tutor_class_types.first.cost
        end
      end
    end
        
    if self.student && self.student.fee.to_f > 0
      return self.student.fee.to_f 
    end 
    
    if self.user && self.user.fee.to_f > 0
      return self.user.fee.to_f 
    end  
    
    Rails.configuration.paypal_amount.to_f     
  end
  
  def cost_from_payment
    return 0 if !self.payment
    return self.payment.amount_by_schedule(self.id)    
  end  
  
  def cost_with_due_from_payment
    return 0 if !self.payment
    return self.payment.amount_due_by_schedule(self.id)    
  end  
  
  def tutor_fee    
    if self.class_type
      if self.student.class_type.exists?(self.class_type)
        tutor_class_types = TutorClass.find_all_by_user_id_and_class_type_id(self.student_id, self.class_type_id)        
        if tutor_class_types.count.nonzero? && tutor_class_types.first.fee && tutor_class_types.first.fee.nonzero?
          return tutor_class_types.first.fee
        end        
      end
      
      if self.user.class_type.exists?(self.class_type)
        tutor_class_types = TutorClass.find_all_by_user_id_and_class_type_id(self.user_id, self.class_type_id)        
        if tutor_class_types.count.nonzero? && tutor_class_types.first.fee && tutor_class_types.first.fee.nonzero?
          return tutor_class_types.first.fee
        end
      end
    end
    
    return 0    
  end
  
  def has_undone_homework?
    undone_homework_tasks = self.homework.where('(is_done IS NULL OR is_done = 0) AND (is_moved IS NULL OR is_moved = 0)')
    if undone_homework_tasks.count == 0
      return false
    end
    return true
  end
  
  def set_remind_time
    self.update({:remind_time => Time.now.to_i})
  end
  
  def set_homework_remind_time
    self.update({:homework_remind_time => Time.now.to_i})
  end
  
  def set_payment_remind_time
    self.update({:payment_remind_time => Time.now.to_i})
  end
    
  def set_real_duration(start_time, end_time, duration)     
    self.update({:real_duration => duration, :start_time => start_time, :end_time => end_time})    
  end
  
  def set_state(state)
    self.update({:state => state})    
  end
  
  def reset_state
    return if self.state && self.state > 8
    if self.time > Time.now.to_i + Rails.configuration.lesson_time_limit
      self.state = nil
    else
      if self.time > Time.now.to_i
        self.state = 2
      else
        if self.time + self.duration > Time.now.to_i + Rails.configuration.lesson_time_limit
          self.state = 3
        else
          if self.time + self.duration > Time.now.to_i
            self.state = 5
          else
            if self.time + self.duration > Time.now.to_i - Rails.configuration.lesson_time_limit
              self.state = 7
            else
              self.state = 8
            end
          end          
        end        
      end
    end
  end
  
  def increase_state
    if self.state
      state = self.state + 1
    else
      state = 1      
    end    
    self.update({:state => state})    
  end
        
  def move_undone_homework_to_schedule(destination)
    puts "Переносим невыполненные пункты ДЗ для урока #{self.id} на урок #{destination.id}"    

    self.homework.each do |task| 
      if not task.is_done and not task.is_moved
        task.set_moved
        task.copy_to_schedule(destination)
      end
    end   
  end
  
  def save_cost
    self.update({:saved_cost => self.cost})     
  end
  
  def actualize_homework
    return unless self.has_undone_homework?
    student = self.student
    student.actualize_homework_with_tutor(self.user_id)    
  end
  
  def finished?
    return true if self.state == 9 || self.state == 10
    return true unless $redis.hlen("langLesson:#{self.id}")
    
    events = $redis.hgetall("langLesson:#{self.id}")
    return true if !events.is_a?(Hash) || events.count.zero?    
    return true if events[events.keys.last] != 'start'
    
    return true if self.user_id.blank? || self.student_id.blank?
    return true unless self.user.online? && self.student.online?
    false
  end
    
  def self.get_coming_lessons(time)
    return self.eager_load(:payment).where("time > :from_time AND time < :to_time AND (remind_time IS NULL OR remind_time < :min_upd_time) AND student_id IS NOT NULL AND schedules.user_id IS NOT NULL", {from_time: Time.now.to_i, to_time: Time.now.to_i + time, min_upd_time: Time.now.to_i - time}).order(time: :asc)
  end
    
  def self.get_coming_homeworks(time)
    return self
    .select('*, (SELECT COUNT(1) FROM homeworks WHERE schedule_id = schedules.id) as homework_count, (SELECT COUNT(1) FROM homeworks WHERE schedule_id = schedules.id AND is_done = 1) as homework_done_count')
    .where("time > :from_time AND time < :to_time AND (homework_remind_time IS NULL OR homework_remind_time < :min_upd_time) AND student_id IS NOT NULL AND (SELECT COUNT(1) FROM homeworks WHERE schedule_id = schedules.id) > (SELECT COUNT(1) FROM homeworks WHERE schedule_id = schedules.id AND is_done = 1)", {from_time: Time.now.to_i, to_time: Time.now.to_i + time, min_upd_time: Time.now.to_i - time}).order(time: :asc)
  end
            
  def self.unpaid_lessons_for_student(student, start_time, end_time)
    student.student_schedule.not_paid.where("time < :end_time AND time > :start_time", {start_time: start_time, end_time: end_time})       
  end
  
  def self.classes_statistics(classes)
    {
      :total => classes.past.count,
      :free => classes.carried_out.free.count,
      :paid => classes.carried_out.paid.count,
      :not_paid => classes.carried_out.not_paid.count,
      :missed => classes.missed.not_paid.count + classes.missed.free.count,
      :missed_paid => classes.missed.paid.count
    }
  end
  
  def self.payments_statistics(classes, tutor)
    payments = 0
    payments_due = 0
    cost = 0
    fee = 0
    unpaid = 0
    overpaid = 0
    
    classes.each do |schedule|
      payments += schedule.cost_from_payment if schedule.paid 
      payments_due += schedule.cost_with_due_from_payment if schedule.paid
      cost += schedule.cost if schedule.carried_out? && !schedule.free?
      fee += schedule.tutor_fee if schedule.carried_out? && schedule.free
      unpaid += schedule.cost if schedule.carried_out? && !schedule.free? && !schedule.paid
      overpaid += schedule.cost if !schedule.carried_out? && !schedule.free? && schedule.paid
    end
    
    {
      :name => tutor.name,
      :payments => payments,
      :payments_due => payments_due.round(2),
      :cost => cost,
      :fee => fee,
      :unpaid => unpaid,
      :overpaid => overpaid,
      :fee_for_transfer => tutor.fee_for_transfer(fee),
      :income => (payments_due - tutor.fee_for_transfer(fee)).round(2)
    }
  end
  
end
