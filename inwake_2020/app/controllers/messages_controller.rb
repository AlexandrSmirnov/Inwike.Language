class MessagesController < WebsocketRails::BaseController
  
  #def get_chat_history
  #  messages = Message.between_users(current_user.id, message[:recipient]).after(message[:time]).sort(time: -1).limit(10)
  #  messages.each do |message|
  #    next if message.delivered || current_user.id != message.recipient
  #    message.update_attribute(:delivered, true)
  #    WebsocketRails.users[message.sender].send_message('update_chat_message', message)   
  #  end   
  #  WebsocketRails.users[current_user.id].send_message('chat_history', messages)    
  #end
  
  def send_chat_message
    #chat_message = Message.new(messages_param)
    chat_message = ChatMessage.new(messages_param)
    chat_message.time = Time.now.to_i * 1000
    if !chat_message.message.blank? && chat_message.save
      chat_message.deliver
    end
  end
  
  def remove_chat_message
    #chat_message = Message.find(message)
    chat_message = ChatMessage.find(message)
    if chat_message && chat_message.sender_id == current_user.id
      chat_message.update({:message => nil, :removed => true})
      WebsocketRails.users[chat_message.recipient_id].send_message('update_chat_message', chat_message)   
      WebsocketRails.users[chat_message.sender_id].send_message('update_chat_message', chat_message)   
    end
  end
  
  def edit_chat_message
    #chat_message = Message.find(message[:id])
    chat_message = ChatMessage.find(message[:id])
    if chat_message && chat_message.sender_id == current_user.id && !message[:message].blank?
      chat_message.update({:message => message[:message], :edited => true})
      WebsocketRails.users[chat_message.recipient_id].send_message('update_chat_message', chat_message)   
      WebsocketRails.users[chat_message.sender_id].send_message('update_chat_message', chat_message)   
    end
  end
  
  def typing_chat_message
    recipient = message.to_i
    WebsocketRails.users[recipient].send_message('typing_chat_message', current_user.id)   
  end
  
  
  private
  def messages_param
    allowed = ['recipient_id', 'sender_id', 'message']
    message.select {|key, value| allowed.include?(key)}
  end
end