include ActionView::Helpers::NumberHelper
class HomeworkFile < ActiveRecord::Base
  belongs_to :homework
  belongs_to :user
  
  mount_uploader :file, FileUploader
  
  before_save { |homework_file| homework_file.title = homework_file.title.truncate(100, :omission => '')}
  after_create { |homework_file| homework_file.message_to_rt 'create' }
  after_destroy { |homework_file| homework_file.message_to_rt 'destroy' }
  
  def truncate_title
    if self.title.length > 100
      self.title.truncate(nb_words_max, :separator => ' ') + " ..."
    end
  end
    
  def message_to_rt(action)    
    if action == 'destroy'
      self.send_to_rt('homework-file-updated', {
          'action' => action, 
          'schedule' => self.homework.schedule, 
          'homework_file' => {
            'id' => self.id
          }
        }
      )
    else        
      self.send_to_rt('homework-file-updated', {
          'action' => action, 
          'schedule' => self.homework.schedule, 
          'homework_file' => {
            'id' => self.id, 
            'title' => self.title, 
            'homework_id' => self.homework_id,
            'time' => self.created_at.to_i,
            'user' => {
              'id' => self.user.id,
              'name' => self.user.name,
              'is_tutor' => self.user.has_role?('tutor')
            },
            'file' => {
              'name' => URI.decode(File.basename(self.file.url)),
              'url' => "/uploads/homework_file/file/#{self.id}/#{File.basename(self.file.url)}",
              'size' => number_to_human_size(self.file.size)
            }
          }
        }
      )
    end    
  end
  
  def send_to_rt(message, data)
    WebsocketRails.users[self.homework.schedule.user_id].send_message(message, data)
    WebsocketRails.users[self.homework.schedule.student_id].send_message(message, data)
  end
  
end
 #