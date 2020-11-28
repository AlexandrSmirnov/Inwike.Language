class Message
  
  include Mongoid::Document
  
  field :sender, :type => Integer
  field :recipient, :type => Integer
  field :message, :type => String
  #field :message_json, :type => String
  field :type, :type => String, default: 'message'
  field :time, :type => Integer
  field :delivered, :type => Boolean, default: false
  field :removed, :type => Boolean
  field :edited, :type => Boolean
  
  index ({ sender: 1, recipient: 1 })
  
  scope :between_users, ->(user1, user2){ any_of({ :sender => user1, :recipient => user2 }, { :sender => user2, :recipient => user1 }) }
  scope :before, ->(time){ return nil if time.zero?; where(:time.lt => time) }
  scope :after, ->(time){ return nil if time.zero?; where(:time.gt => time) }
  scope :not_delivered, -> { where(:delivered => false) }
  
  
  def deliver    
    if WebsocketRails.users[self.recipient].connected?
      self.delivered = true 
      WebsocketRails.users[self.recipient].send_message('chat_message', self)    
      self.save
    else
      User.find(self.recipient).notify_about_message(self)
    end
    
    WebsocketRails.users[self.sender].send_message('chat_message', self)    
  end
  
end