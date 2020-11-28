class sfLesson.classConference extends EventsDispatcher  
  
  #  
  initInterface: ->
    @.setShareScreenAction()  
  
                    
  # 
  redrawConference: ->
    console.log "redrawConference"
    @.initInterface()  
    console.log @callerVideoElement
    console.log @callerScreenElement
    $('#callControl').append @callerVideoElement if @callerVideoElement? and not @callerScreenElement?
    if @callerScreenElement?
      $('#callControl').append @callerScreenElement 
      @callerScreenElement.removeClass 'hidden'
    if @selfVideoElement?
      $('#callControl').append @selfVideoElement
      if @selfScreenElement?
        $('#selfVideo').addClass 'hidden'
        $('#callControl').append @selfScreenElement
  
   
  # 
  shareScreen: ->
    console.log "Запущена публикация видео с экрана"   
       
    $('#screenVideo').remove()
    $('#callControl').append "<div id=\"screenVideo\"></div>"   
    
    errorCallback = (error) ->
      alert 'Something went wrong: ' + error.message
      return
    
      streamCreated: (event) =>
        console.log "Трансляция экрана началась"   
        @selfScreenElement = $('#screenVideo')
      streamDestroyed: (event) =>
        console.log "Трансляция экрана остановлена. Причина: " + event.reason
        @.switchToSelfVideo() if event.reason is 'mediaStopped'
        @selfScreenElement = null
      accessAllowed: (event) =>      
        console.log "Доступ к экрану разрешен."     
        @.publishScreen()
      accessDenied: (event) =>
        console.log event 
        @screenVideoElement = null
        $('#selfVideo').removeClass 'hidden'
        $('#screenVideo').remove()

    
  #    
  showStream: (stream) ->
    if stream.videoType is 'screen'
      @.showScreenStream stream
    else
      @.showVideoStream stream      
    @.trigger 'subscribed'
    
  #  
  switchToSelfVideo: ->
    $('#selfVideo').removeClass 'hidden'
     
  # Функция выводит подсказку и диалоговое окно с запросом доступа к камере и микрофону
  showMediaRequestHint: ->
    console.log "Подсказываем подсказку для запроса доступа к камере"   
    hint = null
    
    switch @.detectBrowser()
      when 'mozilla'  
        hint = new ScreenHint (I18n.t 'lesson.camera_access.mozilla')
        hint.showInFixedPlace {top: 250, left: 130}, {animation: 'pulse', delay: 400}
      when 'chrome'
        hint = new ScreenHint (I18n.t 'lesson.camera_access.webkit')
        hint.showInFixedPlace {top: 40, right: 80}, {animation: 'pulse', delay: 800}  
      when 'webkit'
        hint = new ScreenHint (I18n.t 'lesson.camera_access.webkit')
        hint.showInFixedPlace {top: 40, right: 80}, {animation: 'pulse', delay: 800}  
      when 'opera'
        hint = new ScreenHint (I18n.t 'lesson.camera_access.opera')
        hint.showInFixedPlace {top: 210, right: '46%'}, {animation: 'pulse', delay: 800}  
    hint
    
  # Функция отображает элементы управления для собственного видео
  addSelfCallControls: (element, videoPublisher, audioPublisher) ->
    selfControlsHtml = "<div class=\"self-controls\">
                          <button class=\"self-button toggle-self-audio\"><i class=\"fa fa-microphone self-button__icon #{if audioPublisher? and audioPublisher.stream and not audioPublisher.stream.hasAudio then 'self-button__icon_disabled' else ''}\"></i></button>
                          <button class=\"self-button toggle-self-video\"><i class=\"fa fa-video-camera self-button__icon #{if videoPublisher? and videoPublisher.stream and not videoPublisher.stream.hasVideo then 'self-button__icon_disabled' else ''}\"></i></button>
                        </div>"
    element.find('.self-controls').remove()
    element.append selfControlsHtml
        
    selfAudioToggle = element.find('.toggle-self-audio')
    selfAudioToggle.click (event) =>
      return if not audioPublisher? or not audioPublisher.stream      
      if audioPublisher.stream.hasAudio
        console.log "Отключаем трансляцию аудио"   
        audioPublisher.publishAudio false
        selfAudioToggle.find('i').addClass 'self-button__icon_disabled'
      else
        console.log "Возобновляем трансляцию аудио"   
        audioPublisher.publishAudio true
        selfAudioToggle.find('i').removeClass 'self-button__icon_disabled'
    
    selfVideoToggle = element.find('.toggle-self-video')
    selfVideoToggle.click (event) =>
      return if not videoPublisher? or not videoPublisher.stream      
      if videoPublisher.stream.hasVideo
        console.log "Отключаем трансляцию видео"   
        videoPublisher.publishVideo false
        selfVideoToggle.find('i').addClass 'self-button__icon_disabled'
      else
        console.log "Возобновляем трансляцию видео"  
        videoPublisher.publishVideo true
        selfVideoToggle.find('i').removeClass 'self-button__icon_disabled'
          
  # Функция отправляет серверу сообщение о начале трансляции
  sendStreamingStarted: ->
    console.log "Сообщаем серверу о начале трансляции"
    @socket.trigger 'streaming_started', { lesson_id: @currentLessonId }  
            
  # Функция отправляет серверу сообщение о прекращении трансляции
  sendStreamingEnded: ->
    console.log "Сообщаем серверу об остановке трансляции"
    @socket.trigger 'streaming_ended', { lesson_id: @currentLessonId }    
      
  # Функция возвращает название браузера  
  detectBrowser: ->
    return 'chrome' if /chrome/.test navigator.userAgent.toLowerCase()
    return 'mozilla' if /mozilla/.test(navigator.userAgent.toLowerCase()) and not /webkit/.test(navigator.userAgent.toLowerCase())
    return 'opera' if /opr/.test navigator.userAgent.toLowerCase()
    return 'webkit' if /webkit/.test navigator.userAgent.toLowerCase()
    return 'msie' if /msie/.test navigator.userAgent.toLowerCase()
    return  
    
  isLessonPageOpened: ->
    return true if (window.location.href.match /(student|tutor)\/lesson/) 
    false   