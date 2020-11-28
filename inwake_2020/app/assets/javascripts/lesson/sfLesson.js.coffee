class @sfLesson extends EventsDispatcher

  lessonStates = 
    noLesson : 0
    disabledLesson : 1
    lessonNotSelected : 2
    enabledLesson : 3
    conference : 4
    groupEnabled : 5

  # Конструктор класса
  constructor: (@userData, @socket) ->
    console.log "sfLesson: объект создан"
    @lessonState = lessonStates.noLesson
    @nearestLesson = null
    @.getNearestLesson()
    @.initWebsocketEvents()
    OT.setLogLevel OT.DEBUG
    
  init: ->  
    @.setFullscreenAction()
    @.drawInterface()
    
  initWebsocketEvents: ->
    @socket.unbind 'nearest_lesson'
    @socket.bind 'nearest_lesson', (data) =>   
      @.setNearestLesson data
    
  # Функция получает информацию о ближайшем занятии
  getNearestLesson: ->  
    console.log "Запрашиваем время ближайшего занятия"    
    $.ajax
      url: "/user/nearest_lesson"
      method: 'get'    
      success: (response) =>
        @.setNearestLesson response        
      error: =>
        console.log "При запросе ближайшего занятия произошла ошибка!"
        false 
        
  # Функция устанавливает время ближайшего занятия и обновляет переменную состояния
  setNearestLesson: (nearestLesson) ->
    console.log "Получено ближайшее занятие"
    console.log nearestLesson

    if nearestLesson? and nearestLesson.id? and nearestLesson.id 
      if @nearestLesson?
        @nearestLesson.update nearestLesson
      else
        @nearestLesson = new sfLesson.class nearestLesson
      if nearestLesson.overlapping? and nearestLesson.overlapping.id?
        if @overlappingLesson?
          @overlappingLesson.update nearestLesson.overlapping
        else
          @overlappingLesson = new sfLesson.class nearestLesson.overlapping
      else
        @overlappingLesson = null
      @.updateRoomLessonId()  

    @.updateLessonState()
    @.drawInterface()
    
  updateRoomLessonId: ->
    return if not @classRoom? or not @nearestLesson    
    if @overlappingLesson?
      if @classRoom.id == @overlappingLesson.student
        @classRoom.setNearestLessonId @overlappingLesson.id
      else
        @classRoom.setNearestLessonId @nearestLesson.id
    else
      @classRoom.setNearestLessonId @nearestLesson.id
    
    
  joinRoom: (roomId) ->  
    @classRoom = new sfLesson.classRoom roomId, @userData.id, @socket
    @.updateRoomLessonId()
    @classRoom.unbind('status_updated').bind 'status_updated', =>
      @.drawInterface()
    @classRoom.unbind('class_started').bind 'class_started', =>
      @lessonState = lessonStates.conference
      @.drawInterface()  
    @classRoom.unbind('class_stopped').bind 'class_stopped', =>
      @lessonState = lessonStates.enabledLesson
      @.updateLessonState()      
    
  leaveRoom: ->
    return unless @classRoom?
    @classRoom.leave()
    @classRoom = undefined
    @.updateLessonState()
    @.drawInterface()
    
  updateLessonState: ->  
    return if @lessonState is lessonStates.conference     
    unless @nearestLesson
      @lessonState = lessonStates.noLesson
      return
    if @nearestLesson.enabled    
      @lessonState = if @classRoom? then lessonStates.enabledLesson else lessonStates.lessonNotSelected
    else
      @lessonState = lessonStates.disabledLesson
    
    @lessonState = lessonStates.groupEnabled if @nearestLesson.group

      
  setLessonBadge: ->
    if @lessonState is lessonStates.conference
      $('#lesson-menu-link').append '<span class="badge badge-important record"> </span>'
    else
      $('#lesson-menu-link').find('.badge.record').remove()
    
  drawInterface: ->
    console.log "lesson state: #{@lessonState}"
    @.setLessonBadge()
    return unless @.isLessonPageOpened()
    switch @lessonState
      when lessonStates.noLesson then @.setNoLesson()
      when lessonStates.disabledLesson then @.setDisabledLesson()
      when lessonStates.lessonNotSelected then @.setLessonNotSelected()
      when lessonStates.enabledLesson then @.setEnabledLesson()
      when lessonStates.conference then @.setConference()
      when lessonStates.groupEnabled then @.showGroup()
        
  setStatusText: (text) ->     
    $('#status').html text
    
  showStatusOnly: ->
    $('#status').show()
    $('#studentSelectionBox').hide()
    $('#leaveRoomBox').hide()
    $('#rejectButton').hide()
    $('#callControl').addClass 'hidden'
    $('#startButton').hide()
        
  setNoLesson: ->
    @.showStatusOnly()
    @.setStatusText I18n.t('lesson.no_nearest_lessons')
    
  setLessonNotSelected: ->
    @.showStatusOnly()
    @.setStatusText (I18n.t 'lesson.nearest_lesson_select_student', {currentTimeFormated: @nearestLesson.formattedTime(), student: @nearestLesson.name})
    $('#studentSelectionBox').html('').show()
    
  setDisabledLesson: ->
    return unless @nearestLesson?
    @.showStatusOnly()
    @.setStatusText I18n.t('lesson.nearest_lesson', {currentTimeFormated: @nearestLesson.formattedTime()}) 
    
  setEnabledLesson: ->
    return unless @nearestLesson?
    @.showStatusOnly()
    switch @classRoom.buttonState 
      when sfLesson.classRoom.startButtonStates.userOffline then @.setStatusText @.getEnabledLessonText()
      when sfLesson.classRoom.startButtonStates.userOnline then @.setStatusText @.getOnlineLessonText()
      when sfLesson.classRoom.startButtonStates.requestSended then @.setStatusText @.getOnlineLessonText()
      when sfLesson.classRoom.startButtonStates.ring then @.setStatusText @.getLessonStartRequestText()
      when sfLesson.classRoom.startButtonStates.busy then @.setStatusText @.conferenceBusyText()
         
    $('#startButton').show()
    @classRoom.drawButton()
    
  setConference: ->
    $('#status').hide()
    $('#studentSelectionBox').hide()
    $('#leaveRoomBox').hide()
    $('#startButton').hide()
    $('#rejectButton').hide()
    $('#callControl').removeClass 'hidden'
    @classRoom.conference.redrawConference() if @classRoom.conference?

  showGroup: ->
    console.log("Group")
    $('#status').hide()
    $('#studentSelectionBox').hide()
    $('#leaveRoomBox').hide()
    $('#startButton').hide()
    $('#rejectButton').hide()

    $.ajax
      url: "/user/enter_group/#{@nearestLesson.id}"
      method: 'get'    
      success: (response) =>
        frame = $('#jitsiFrame')
        frame.removeClass 'hidden'
      error: =>
        false
       
  getDisabledLessonText: ->
    I18n.t 'lesson.nearest_lesson', {currentTimeFormated: @nearestLesson.formattedTime()}
                
  getEnabledLessonText: ->
    I18n.t 'lesson.nearest_lesson_tutor_offline', {currentTimeFormated: @nearestLesson.formattedTime()}
    
  getOnlineLessonText: ->
    I18n.t 'lesson.nearest_lesson_online', {currentTimeFormated: @nearestLesson.formattedTime()}
    
  getLessonStartRequestText: ->
    I18n.t 'lesson.lesson_start_request'
    
  conferenceBusyText: ->
    I18n.t 'lesson.conference_busy'    
    
  setFullscreenAction: ->
    $('#fullscreen').off('click').on 'click', =>
      $("#conference-box").toggleFullScreen()
        
    $(document).off('fullscreenchange').on 'fullscreenchange', =>
      if $(document).fullScreen()
        $("#conference-box").addClass 'full_screen'
      else
        $("#conference-box").removeClass 'full_screen'
    
  isLessonPageOpened: ->
    return true if (window.location.href.match /(student|tutor)\/lesson/) 
    false
    
    
class @sfLessonStudent extends sfLesson
  constructor: (@userData, @socket) ->  
    super
    @.joinRoom @userData.id
    
    
class @sfLessonTutor extends sfLesson
  init: ->
    super
    $('#leaveRoomButton').off('click').on 'click', =>
      @.leaveRoom()
  
  joinRoom: (userId) ->  
    super
    @.updateLessonState()
    @.drawInterface()
    
  setDisabledLesson: ->
    super
    $('#leaveRoomBox').hide()
    
  setEnabledLesson: ->  
    super
    if @classRoom.buttonState is sfLesson.classRoom.startButtonStates.requestSended
      $('#leaveRoomButton').attr 'disabled', 'disabled' 
    else
      $('#leaveRoomButton').removeAttr 'disabled'
    $('#leaveRoomBox').show()
    
  getDisabledLessonText: ->
    I18n.t 'lesson.nearest_lesson', {currentTimeFormated: @nearestLesson.formattedTime()}
    
  getEnabledLessonText: ->
    I18n.t 'lesson.nearest_lesson_student_offline', {currentTimeFormated: @nearestLesson.formattedTime(), student: @nearestLesson.name}
  
  getLessonStartRequestText: ->
    I18n.t 'lesson.lesson_student_start_request'