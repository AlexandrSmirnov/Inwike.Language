class ChatMessage < ActiveRecord::Base
  mount_uploader :file_path, ChatMessageFileUploader
  before_save :set_file_size
  
  belongs_to :sender, class_name: "User"
  belongs_to :recipient, class_name: "User"
  
  scope :between_users, (lambda do |user1, user2| 
    where(["(sender_id = ? AND recipient_id = ?) OR (recipient_id = ? AND sender_id = ?)", user1, user2, user1, user2])    
  end)

  scope :after, (lambda do |time| where(["time > ?", time]) end)
  scope :before, (lambda do |time| where(["time < ?", time]) end)
  scope :search, (lambda do |word| 
    #search_text = "#{word}*"  
    search_filename = "%#{word}%"  
    where(["(message LIKE ?) OR (file_name LIKE ?)", search_filename, search_filename]) 
    #where(["(MATCH (message) AGAINST (? IN BOOLEAN MODE)) OR (file_name LIKE ?)", search_text, search_filename]) 
  end)
  scope :not_delivered, -> { where("delivered != 1") }
  
  
  def deliver    
    if WebsocketRails.users[self.recipient_id].connected?
      WebsocketRails.users[self.recipient_id].send_message('chat_message', self)    
      self.update({:delivered => true})
    else
      self.recipient.notify_about_message(self)
    end
    
    WebsocketRails.users[self.sender_id].send_message('chat_message', self)    
  end
  
  
  private

  def set_file_size
    if self.is_file && file_path.present? && file_path_changed?
      self.file_size = file_path.file.size
    end
  end
  
end
