namespace :tools do
  desc "TODO"
  
  task move_messages: :environment do
    step = (Message.all.count / 100).floor
    current_step = 0
    i = 0
    
    Message.all.sort(time: 1).each do |message|    
      if i == current_step
        puts "moved: #{i} / #{Message.all.count}"
        current_step += step
      end
      i += 1
            
      new_message = ChatMessage.new({
          :sender_id => message.sender,
          :recipient_id => message.recipient,
          :time => message.time,
          :delivered => message.delivered,
          :removed => message.removed,          
          :edited => message.edited          
      })
      new_message.save()
      if message.type == 'file'
        next if !message.message || message.message.empty?
        file_data = JSON.parse(message.message)
        next if !file_data.is_a?(Hash) || !file_data.has_key?('id') || !file_data['id'].is_a?(Hash) || !file_data['id'].has_key?('$oid')
        file = MessageFile.find(file_data['id']['$oid'])
        new_message.update({
            :is_file => true,
            :file_name => file_data['filename'],
            :file_path => file.path,
            :file_size => file_data['size']
        })
      else  
        new_message.update({ :message => message.message })  
      end
    end
    
    puts "moved #{Message.all.count}"
    puts 'done!'
  end

end
