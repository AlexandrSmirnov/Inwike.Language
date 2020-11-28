class @sfRealtime extends EventsDispatcher

  class sfWebSocket extends WebSocketRails  
    ping_timeout = 21000
    ping_timer = null
  
    new_message: (data) =>
      for socket_message in data
        event = new WebSocketRails.Event( socket_message )
        if event.is_result()
          @queue[event.id]?.run_callbacks(event.success, event.data)
          delete @queue[event.id]
        else if event.is_channel()
          @dispatch_channel event
        else if event.is_ping()
          @pong()
          @.set_ping_timer()
        else
          @dispatch event

        if @state == 'connecting' and event.name == 'client_connected'          
          @connection_established event.data
          @.set_ping_timer()
          
    set_ping_timer: ->
      clearTimeout ping_timer
      ping_timer = setTimeout @.ping_timer_action, ping_timeout      
          
    ping_timer_action: =>
      console.log "ping перестал приходить!"
      @disconnect()
      close_event = new WebSocketRails.Event(['connection_closed'])
      @dispatch close_event
          
    unbind: (event) ->
      @.callbacks[event].length = 0 if @.callbacks[event]

    
  # Конструктор класса
  constructor: ->  
  
  # Инициализация
  init: ->
    if @socket?
      console.log "realtime: already connected!"
      @.setConnectionBadge()
      @.initModules()
      return
  
    userDataCallback = =>
      successCallback = =>
        @.initModules()
        return    
      failureCallback = =>
        return        
      @.connect successCallback, failureCallback if not socket?
    
    @.getUserData userDataCallback
        
  # Функция осуществляет соединение с сервером  
  connect: (successCallback, failureCallback) -> 
    if @socket?
      successCallback()
      return
    
    @socket = new sfWebSocket("#{location.host}/websocket")
    @socket.on_open = (data) =>
      console.log "realtime: connected!"
      @socket.unbind 'open'
      @.trigger 'connected'
      @.setConnectionBadge()
      successCallback()
      #lesson.restoreOpentokSession() if lesson?
                
    @socket.unbind 'connection_closed'
    @socket.bind 'connection_closed', =>
      console.log "realtime: disconnected!"      
      @.trigger 'disconnected'
      @.setConnectionBadge()
      setTimeout (=>
        console.log "realtime: reconnecting..."    
        @.setConnectionBadge()
        @socket.reconnect()
        return
      ), 4000
      
  # Функция вызывает callback если существует socket, иначе вызывает callback при успешном соединении   
  ready: (callback) ->
    if @socket?
      callback()
      return
    @.bindOnce 'connected', callback
          
  # Функция запрашивает информацию о пользователе  
  getUserData: (successCallback) ->
    $.ajax
      url: "/user/data"
      method: 'get'
      success: (response) =>
        @userData = response
        successCallback()
        return
      error: ->
        alert("Error!")
        false  
   
  # 
  initModules: ->
    console.log "realtime: init modules.."
    @.initMessenger()
    @.initLesson()
            
  # Функция инициализирует объект lesson 
  initLesson: ->
    console.log "realtime: initLesson"    
    if not @lesson?
      if @userData.role is 'tutor'
        @lesson = new sfLessonTutor @userData, @socket
      else  
        @lesson = new sfLessonStudent @userData, @socket
      
    @lesson.init()    
    
    @lesson.unbind 'roomenter'
    @lesson.bind 'roomenter', (data) =>
      return if @userData.role isnt 'tutor' or not data.userId?
      console.log 'roomenter'
      #messenger.changeChatRecipient data.userId
    @.bind 'connected', =>  
      @lesson.classRoom.reconnect if @lesson.classRoom?
      @lesson.drawInterface()
        
  # Функция инициализирует объект messenger
  initMessenger: ->
    if not @messenger?
      @messenger = new sfMessenger @socket, @userData
      @.bind 'disconnected', =>  
        @messenger.disableChat()
      @.bind 'connected', =>  
        @messenger.enableChat()
        @messenger.loadNextMessages()
    @messenger.init()
    return
  
  # Функция отображает иконку активного занятия
  checkLessonBadge: ->
    return if not @lesson?
    if @lesson.isLessonInProgress() and not $('#lesson-menu-link').find('.badge.record').length
      $('#lesson-menu-link').append '<span class="badge badge-important record"> </span>'
        
  # Функция возвращает web socket
  getWebSocket: ->
    return @socket    
    
  # Функция проверяет, установлено ли соединение с сервером  
  isConnectionEstablished: ->
    return true if @socket
    return false
        
  #      
  setConnectionBadge: ->
    console.log 'setting connection badges'    
    html = switch 
      when @socket.state is 'disconnected' then '<span class="label label-important"><i class="fa fa-frown-o"></i> Disconnected</span>'
      when @socket.state is 'connecting' then '<span class="label label-warning"><i class="fa fa-meh-o"></i> Connecting...</span>'
      when @socket.state is 'connected' then '<span class="label label-success"><i class="fa fa-smile-o"></i> Online</span>'
    $('.connection-box').html html
    
  #  
  isLessonPageOpened: ->
    return true if (window.location.href.match /(student|tutor)\/lesson/) 
    false  