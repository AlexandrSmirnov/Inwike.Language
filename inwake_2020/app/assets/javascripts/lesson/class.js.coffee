class sfLesson.class extends EventsDispatcher  

  constructor: (lessonObject) ->
    console.log "sfClass: объект создан"
    @.setFields lessonObject

  update: (lessonObject) ->
    @.setFields lessonObject
  
  setFields: (lessonObject) ->
    @id = lessonObject.id 
    @time = lessonObject.time 
    @duration = lessonObject.duration 
    @tutor = lessonObject.tutor 
    @student = lessonObject.student 
    @enabled = lessonObject.enabled 
    @name = lessonObject.name or null
    @group = lessonObject.group or false

  formattedTime: ->
    moment.unix(@time).format I18n.t 'datetime.calendar.date_and_time_format' 