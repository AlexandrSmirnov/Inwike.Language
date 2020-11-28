class MessengerController < ApplicationController
  
  before_filter :authenticate_user!
  layout "admin"
  
  def history  
    messages = []    
    
    if params.has_key?(:from_time)
      if params.has_key?(:to_time)
        #messages = Message.between_users(current_user.id, params[:recipient]).after(params[:from_time].to_i).before(params[:to_time].to_i).sort(time: -1).limit(10)  
        messages = ChatMessage.between_users(current_user.id, params[:recipient]).after(params[:from_time].to_i).before(params[:to_time].to_i).order('id DESC').limit(10)    
      else
        #messages = Message.between_users(current_user.id, params[:recipient]).after(params[:from_time].to_i).sort(time: -1)     
        messages = ChatMessage.between_users(current_user.id, params[:recipient]).after(params[:from_time].to_i).order('id DESC')
      end      
    else  
      if params.has_key?(:to_time)
        #messages = Message.between_users(current_user.id, params[:recipient]).before(params[:to_time].to_i).sort(time: -1).limit(10)    
        messages = ChatMessage.between_users(current_user.id, params[:recipient]).before(params[:to_time].to_i).order('id DESC').limit(10)   
      else
        #messages = Message.between_users(current_user.id, params[:recipient]).sort(time: -1).limit(10)         
        messages = ChatMessage.between_users(current_user.id, params[:recipient]).order('id DESC').limit(10)     
      end
    end
    
    messages.each do |message|
      next if message.delivered || current_user.id != message.recipient_id
      message.update({:delivered => true})
      WebsocketRails.users[message.sender_id].send_message('update_chat_message', message)   
    end   
    
    render :json => { :messages => messages }        
  end
  
  def search  
    messages = []    
    
    if params.has_key?(:recipient) && params.has_key?(:word)      
      if params.has_key?(:from_time)
        if params.has_key?(:to_time)
          messages = ChatMessage.between_users(current_user.id, params[:recipient]).after(params[:from_time].to_i).before(params[:to_time].to_i).search(params[:word]).order('id DESC').limit(10)    
        else   
          messages = ChatMessage.between_users(current_user.id, params[:recipient]).after(params[:from_time].to_i).search(params[:word]).order('id DESC')
        end      
      else  
        if params.has_key?(:to_time)
          messages = ChatMessage.between_users(current_user.id, params[:recipient]).before(params[:to_time].to_i).search(params[:word]).order('id DESC').limit(10)   
        else     
          messages = ChatMessage.between_users(current_user.id, params[:recipient]).search(params[:word]).order('id DESC').limit(10)     
        end
      end
    end
    
    render :json => { :messages => messages }   
  end
  
  def upload_file

    result = 0
    files = params[:message][:name]
    
    files.each do |filename|
      if filename.is_a?(ActionDispatch::Http::UploadedFile) && filename.original_filename
        #file = MessageFile.new(:name => filename.original_filename, :path => filename, :user_id => current_user.id)
        file = ChatMessage.new(message_param.merge({:is_file => true, :file_name => filename.original_filename, :file_path => filename}))

        if file.save
          #file_json = {:filename => file.name, :id => file._id, :size => file.size}.to_json
          #chat_message = Message.new(message_param.merge({:message => file_json, :type => 'file'}))
          #if chat_message.save 
            file.deliver
            result = 1
          #end
        end
      end
    end      
        
    render :json => { :result => result }
  end
  
  def get_file
    #message = Message.find(params[:message])
    message = ChatMessage.find(params[:message])
    
    if (message.recipient_id == current_user.id || message.sender_id == current_user.id) && message.is_file
      #file_data = JSON.parse(message.message)
      #file = MessageFile.find(file_data['id']['$oid'])
      
      send_file(message.file_path.path, :filename => message.file_name, :disposition => 'inline') and return
    end
    
    render :text => 'Error'
  end
  
  def update_files
    render nothing:true #and return unless current_user.has_role?('admin')
    
    #Message.all.sort(time: 1).each do |message|    
    #  new_message = ChatMessage.new({
    #      :sender_id => message.sender,
    #      :recipient_id => message.recipient,
    #      :time => message.time,
    #      :delivered => message.delivered,
    #      :removed => message.removed,          
    #      :edited => message.edited          
    #  })
    #  new_message.save()
    #  if message.type == 'file'
    #    file_data = JSON.parse(message.message)
    #    file = MessageFile.find(file_data['id']['$oid'])
    #    new_message.update({
    #        :is_file => true,
    #        :file_name => file_data['filename'],
    #        :file_path => file.path,
    #        :file_size => file_data['size']
    #    })
    #  else  
    #    new_message.update({ :message => message.message })  
    #  end
      #message.update_attribute(:message_json, message.message.to_json)
      #message.update_attribute(:message, message.message_json)
      #message.update_attribute(:message_json, nil)
      #puts message.message.to_json
    #end
    
    #render text: 'done'
  end
    
  
  private
  def message_param
    params.require(:message).permit(:recipient_id, :sender_id, :time)
  end 
  
end
