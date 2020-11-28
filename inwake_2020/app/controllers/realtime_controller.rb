class RealtimeController < WebsocketRails::BaseController
  include WebsocketRails::Logging
  
  def user_data
    return unless current_user
    WebsocketRails.users[current_user.id].send_message('client_info', current_user.get_user_data_as_json)
  end
  
  def connected
    puts "connected"
    log(:debug, "Подключен пользователь #{current_user.id} #{current_user.name}") if current_user
  end
  
  def disconnected
    puts "disconnected"
    log(:debug, "Соединение разорвано: пользователь #{current_user.id} #{current_user.name}") if current_user
  end
  
  def pong
    puts "pong"
  end
  
  def streaming_started
    return unless current_user && message[:lesson_id]
    set_streaming_timestamp(message[:lesson_id], 'start')
  end
  
  def streaming_ended
    return unless current_user && message[:lesson_id]
    set_streaming_timestamp(message[:lesson_id], 'stop')
  end
  
  private
  def set_streaming_timestamp(lesson_id, type)
    if $redis.hlen("langLesson:#{lesson_id}")      
      return if $redis.hvals("langLesson:#{lesson_id}").last == type     
    end
    $redis.hset("langLesson:#{lesson_id}", DateTime.now.strftime('%Q'), type)
  end
  
end