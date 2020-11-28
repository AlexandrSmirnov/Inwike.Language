class Homework < ActiveRecord::Base
  belongs_to :schedule
  has_many :homework_file
  
  after_create { |homework| homework.message_to_rt 'create' }
  after_update { |homework| homework.message_to_rt 'update' }
  after_destroy { |homework| homework.message_to_rt 'destroy' }
      
  def message_to_rt(action) 
    schedule = Schedule
                .select('*, 
                        (SELECT COUNT(1) FROM homeworks WHERE schedule_id = schedules.id) as homework_count, 
                        (SELECT COUNT(1) FROM homeworks WHERE schedule_id = schedules.id AND is_done = 1) as homework_done_count'
                )
                .find(self.schedule_id)
                
    schedule_array = {
      :id => schedule.id,
      :user_id => schedule.user_id,
      :student_id => schedule.student_id,
      :homework_progress => schedule.homework_progress,
      :homework_class => schedule.homework_class, 
      :homework_icon => schedule.homework_icon, 
      :homework_tip => schedule.homework_tip
    }
    
    if action == 'destroy'
      self.send_to_rt('homework-updated', {
          'action' => action, 
          'schedule' => schedule_array, 
          'homework' => {
            'id' => self.id
          }
        }
      )      
    else
      self.send_to_rt('homework-updated', {
            'action' => action, 
            'schedule' => schedule_array,
            'homework' => { 
              :id => self.id,
              :title => self.title,
              :text => self.text.bbcode_to_html.html_safe,
              :by_student => self.by_student,
              :is_done => self.is_done
            }
          }
        )   
    end
  end
  
  def send_to_rt(message, data)
    WebsocketRails.users[self.schedule.user_id].send_message(message, data)
    WebsocketRails.users[self.schedule.student_id].send_message(message, data)
  end
  
  def set_moved
    self.update({:is_moved => true})
  end
  
  def copy_to_schedule(schedule)
    homework = schedule.homework.new({ :title => self.title, :text => self.text, :by_student => self.by_student })
    homework.save
  end
  
end
