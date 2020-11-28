class Comment < ActiveRecord::Base
  belongs_to :schedule
  belongs_to :user
  
  after_create { |comment| comment.message_to_rt 'create' }
  after_destroy { |comment| comment.message_to_rt 'destroy' }
    
  def message_to_rt(action)
    if action == 'destroy'
      self.send_to_rt('comment-updated', {
          'action' => action, 
          'schedule' => self.schedule, 
          'comment' => {
            'id' => self.id
          }
        })      
    else
      self.send_to_rt('comment-updated', {
            'action' => action, 
            'schedule' => self.schedule, 
            'comment' => {
              'id' => self.id, 
              'text' => self.text, 
              'time' => self.created_at.to_i, 
              'user' => {
                'id' => self.user.id,
                'name' => self.user.name
              }     
            }
          })    
    end
  end
  
  def send_to_rt(message, data)
    WebsocketRails.users[self.schedule.user_id].send_message(message, data)
    WebsocketRails.users[self.schedule.student_id].send_message(message, data)
  end
  
end
