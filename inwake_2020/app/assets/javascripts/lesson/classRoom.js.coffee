class sfLesson.classRoom extends EventsDispatcher  

  startButtonStates = 
    userOffline : 0
    userOnline : 1
    requestSended : 2
    ring : 3
    busy : 4

  @startButtonStates = startButtonStates

  constructor: (@id, @selfId, @socket) ->
    console.log "classRoom: объект создан"
    @nearestLessonId = null
    @buttonState = startButtonStates.userOffline
    @ringSoundLoaded = false
    @ringSound = new Howl(
      urls: ['/sounds/ring.m4a']
      loop: true
      onload: =>
        console.log 'Ring sound loaded'
        @ringSoundLoaded = true
        return
    )    
      
  setNearestLessonId: (@nearestLessonId) ->
        
  # Инициализация событий объекта classConference
  initConferenceEvents: ->
    return unless @conference
    @conference.unbind('destroyed').bind 'destroyed', =>
      @conference = null
      @.sendFreeToOtherSelfClients()
      @.trigger 'class_stopped'
      @buttonState = startButtonStates.userOnline 
    @conference.unbind('disconnected').bind 'disconnected', =>
      @conference = null
      @.sendFreeToOtherSelfClients()
      @.trigger 'class_stopped'
      @buttonState = startButtonStates.userOnline 
    
  # Изменение состояния кнопки начала занятий
  drawButton: ->
    console.log "start button state: #{@buttonState}"
    @ringSound.stop() if @ringSoundLoaded and @buttonState isnt startButtonStates.ring
    switch @buttonState
      when startButtonStates.userOffline then @.setUserOffline()
      when startButtonStates.userOnline then @.setUserOnline()
      when startButtonStates.requestSended then @.setRequestSended()
      when startButtonStates.ring then @.setRing()
      when startButtonStates.busy then @.setBusy()
  
  # Состояние "Собеседник не подключен"
  setUserOffline: ->    
    $('#startButton').html (I18n.t 'lesson.start_lesson')
    $('#startButton').removeClass 'blinking'
    $('#startButton').attr 'disabled', 'disabled'
  
  # Состояние "Собеседник онлайн"  
  setUserOnline: ->
    $('#startButton').html (I18n.t 'lesson.start_lesson')
    $('#startButton').removeClass 'blinking'
    $('#startButton').removeAttr 'disabled'
    $('#startButton').off('click').on 'click', (event) =>
      @conference.createStream =>       
        if @buttonState is startButtonStates.ring
          @ringSound.stop()
          @.sendBusyToOtherSelfClients()
          @conference.publishStream()
          @.trigger 'class_started'  
          return
        @conference.bindOnce 'subscribed', =>
          console.log 'conference: subscribed'
          @conference.publishStream()
          @.trigger 'class_started'  
        @.sendCallRequst()
        @buttonState = startButtonStates.requestSended
        @.trigger 'status_updated'
      
  # Состояние "Запрос на начало занятия отправлен"   
  setRequestSended: ->
    $('#startButton').html "<i class=\"fa fa-circle-o-notch fa-spin\"></i> #{I18n.t 'general.cancel'}"
    $('#startButton').off('click').on 'click', (event) =>
      @.sendCancelRequst()
      @conference.deleteStream()
      @buttonState = startButtonStates.userOnline
      @.trigger 'status_updated'
      @conference = undefined
      
  # Состояние "Вызов"     
  setRing: ->
    $('#startButton').addClass 'blinking'    
    $('#rejectButton').show()
    $('#rejectButton').off('click').on 'click', =>
      @.sendPeerSignal "callReject", @callEvent.from
      @.sendCancelToOtherSelfClients()
      $('#rejectButton').hide()
      @buttonState = startButtonStates.userOnline
      @.trigger 'status_updated'
    $('#startButton').off('click').on 'click', =>
      @ringSound.stop()
      @.sendBusyToOtherSelfClients()
      @.initConferenceEvents()
      @conference.createStream =>
        @conference.publishStream()
        @.trigger 'class_started'
      
  # Состояние "Конференция занята"     
  setBusy: ->
    $('#startButton').html (I18n.t 'lesson.start_lesson')
    $('#startButton').removeClass 'blinking'
    $('#startButton').attr 'disabled', 'disabled'
    $('#startButton').off 'click'
            