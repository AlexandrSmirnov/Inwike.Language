$("#external-events div.external-event").each ->
  eventObject = 
    title: $.trim($(this).text())
    className: if $(this).hasClass("occupied") then "occupied" else "vacant"
    editable: true
    duration: '01:00'
    
  eventObject.id = -1 if $(this).hasClass("occupied")    
  $(this).data "event", eventObject
  
  # make the event draggable using jQuery UI
  $(this).draggable
    zIndex: 999
    revert: true # will cause the event to go back to its
    revertDuration: 0 #  original position after the drag

  return
  
  
changeTimezone = (timezone) ->
  $('#calendar').fullCalendar 'destroy'
  renderCalendar timezone
  
  
# Функция определяет высоту календаря
getCalendarHeight = ->
  return 500 if $(window).height() < 500
  return $(window).height() - 280
  
# Функция устанавливает высоту календаря при изменении размеров окна  
setCalendarHeight = ->
  $('#calendar').fullCalendar 'option', 'height', getCalendarHeight()
  
renderCalendar = (timezone = 'local') ->  
  @calendarTimezone = timezone
  $("#calendar").fullCalendar
    header:
      left: "prev,next today"
      right: "month,agendaWeek,agendaDay"

    height: getCalendarHeight()
    editable: true
    droppable: true
    disableResizing: true
    defaultView: 'agendaWeek'
    allDaySlot: false
    defaultEventMinutes: 60
    events: "/tutor/calendar/list"
    windowResize: setCalendarHeight
    firstHour: 7
    firstDay: I18n.t 'datetime.calendar.first_week_day'
    columnFormat:
      week: I18n.t 'datetime.calendar.week_date_format'
      day: I18n.t 'datetime.calendar.day_date_format'
    axisFormat: I18n.t 'datetime.calendar.time_format'
    dayNames: I18n.t 'datetime.day_names'
    dayNamesShort: I18n.t 'datetime.day_names_short'
    buttonText:
      today: I18n.t 'datetime.calendar.today'
      month: I18n.t 'datetime.calendar.month'
      week: I18n.t 'datetime.calendar.week'
      day: I18n.t 'datetime.calendar.day'
    eventOverlap: true  
    timezone: timezone

    eventReceive: (event) ->
      if event.end.valueOf() < $.fullCalendar.moment().valueOf()
        $('#calendar').fullCalendar 'removeEvents', event.id
        return
      displayMessageSetLesson event              

    eventDrop: (event, delta, revertFunc, jsEvent, ui, view) => 
      if getTimeWithCorrectTimezone(event.end).valueOf() < $.fullCalendar.moment().valueOf()
        revertFunc()
        return 
      editSchedule event
      return    

    eventClick: (event, jsEvent, view) ->
      if event.studentId
        displayMessageCancelLesson event
      else
        displayMessageVacant event      
      return
      
    viewRender: (view) ->
      if first
        first = false
      else
        window.clearInterval timelineInterval
      timelineInterval = window.setInterval( ->
        setTimeline(view)
      , 300000)
      try
        setTimeline(view)
      catch err
      return  
    
    
# Функция добавляет новое событие
addSchedule = (eventObject) =>
  startTime = getTimeWithCorrectTimezone eventObject.start
  endTime = getTimeWithCorrectTimezone eventObject.end
  $.ajax
    url: '/tutor/calendar'
    method: 'post'
    data:
      authenticity_token: AUTH_TOKEN
      schedule:
        time: startTime.unix()
        offset: startTime.utcOffset()
        duration: endTime.unix() - startTime.unix()
        student_id: if eventObject.studentId? then eventObject.studentId else null
        class_type_id: eventObject.class_type
        free: true
        group: true
     success: (response) =>
      eventObject.id = response.id if response.result 
      eventObject._id = response.id.toString() if response.result 
      return
     error: ->
      alert("Error!")
      false
  return

# Функция обновляет существующее событие
editSchedule = (eventObject) =>
  return if not (eventObject.id > 0)
  startTime = getTimeWithCorrectTimezone eventObject.start
  endTime = getTimeWithCorrectTimezone eventObject.end
  $.ajax
    url: "/tutor/calendar/#{eventObject.id}"
    method: 'post'
    data:
      authenticity_token: AUTH_TOKEN
      _method : 'patch'
      schedule:
        time: startTime.unix()
        offset: startTime.utcOffset()
        duration: endTime.unix() - startTime.unix()
        student_id: if eventObject.studentId? then eventObject.studentId else null
        deferred_payment: if eventObject.deferred_payment then true else false
        free: true
        lease_paid: if eventObject.lease_paid then true else false
        group: true
        class_type_id: eventObject.class_type
        carried_out: eventObject.carried_out
     success: (response) =>  
      return
     error: ->
      alert("Error!")
      false
  return
  
# Функция отображает информацию о событии 
displayMessageVacant = (eventObject) ->
  start = eventObject.start.format "h:mm A"
  end = eventObject.end.format "h:mm A"
  
  scheduleButtonHtml = ''
  if eventObject.editable
    scheduleButtonHtml = "<div class=\"eventInfoBody__buttons\">
                            <button type=\"button\" class=\"btn btn-xs btn-success eventAddLesson\">#{I18n.t 'calendar.schedule_lesson'}</button>
                          </div>"
  
  $("#events-info").html ''  
  html = "<div class=\"panel panel-default eventInfoBlock\">
              <div class=\"panel-body eventInfoBody\">
                <div class=\"eventInfoBody__text\">#{I18n.t 'calendar.free_time_from', {start: start, end: end}}</div>
                #{scheduleButtonHtml}
                <div class=\"eventInfoBody__buttons\">
                  <button type=\"button\" class=\"btn btn-xs btn-default eventWindowClose\">#{I18n.t 'general.close'}</button>
                </div>
              </div>
          </div>"
  $("#events-info").append html
    
  $(".eventInfoBlock .eventWindowClose").click ->
    $(this).closest(".eventInfoBlock").remove()
    return
    
  $(".eventInfoBlock .eventDestroy").click ->
    destroySchedule eventObject
    $(this).closest(".eventInfoBlock").remove()
    return
    
  $(".eventInfoBlock .eventAddLesson").click ->
    displayMessageSetLesson eventObject
    $(this).closest(".eventInfoBlock").remove()
    return
  
  return
    
# Функция удаляет событие
destroySchedule = (eventObject) =>
  return if not (eventObject.id > 0)
  $.ajax
    url: "/tutor/calendar/#{eventObject.id}"
    method: 'post'
    data:
      authenticity_token: AUTH_TOKEN
      _method : 'delete'
    success: (response) =>  
      $('#calendar').fullCalendar 'removeEvents', eventObject.id
      return
    error: ->
      alert("Error!")
      false  

  return

# Функция отображает окно добавления занятия 
displayMessageSetLesson = (eventObject) ->

  start = eventObject.start.format "h:mm A"
  end = eventObject.end.format "h:mm A"
  
  selectHtml = "<select class=\"form-control input-sm eventClassType\">"
  selectHtml += "<option value=\"\">#{I18n.t 'calendar.select_type'}</option>"
  for type of CLASS_TYPES
    selectHtml += "<option value=\"#{type}\">#{CLASS_TYPES[type]}</option>"
  selectHtml += "</select>"  
   
  html = "<div class=\"panel panel-default eventInfoBlock\">
              <div class=\"panel-body eventInfoBody\">
                <div class=\"eventInfoBody__text\">
                  #{I18n.t 'calendar.schedule_lesson_on_time', {start: start, end: end}}<br/>   
                  #{selectHtml}
                  <select class=\"form-control input-sm eventStudentSelect\">
                    <option value=\"\">#{I18n.t 'calendar.select_student'}</option>
                  </select>
                </div>
                <div class=\"eventInfoBody__buttons\">
                  <button type=\"button\" class=\"btn btn-xs btn-success eventAddLesson\">#{I18n.t 'calendar.schedule'}</button>
                  <button type=\"button\" class=\"btn btn-xs btn-default eventWindowClose\">#{I18n.t 'general.close'}</button>
                </div>
              </div>
          </div>"
  $("#events-info").append html  
  
  for student of STUDENTS
    $("#events-info .eventStudentSelect").append "<option value=\"#{student}\">#{STUDENTS[student]}</option>"
    
  $(".eventInfoBlock .eventWindowClose").click ->
    $('#calendar').fullCalendar 'removeEvents', -1 if $.trim(eventObject.className) is "occupied"   
    $(this).closest(".eventInfoBlock").remove()
    return
    
  $(".eventInfoBlock .eventAddLesson").click ->  
    return if (not $(this).closest(".eventInfoBlock").find(".eventStudentSelect").val()?) or
              (not $(this).closest(".eventInfoBlock").find(".eventStudentSelect").val().length)
    
    studentId = $(this).closest(".eventInfoBlock").find(".eventStudentSelect").val()
        
    eventObject.studentId = studentId
    eventObject.title = STUDENTS[studentId]
    eventObject.class_type = $(".eventClassType").val()
    eventObject.lease = LEASE[studentId]
    
    if $.trim(eventObject.className) is "occupied" 
      addSchedule eventObject
    else
      editSchedule eventObject
        
    $(this).closest(".eventInfoBlock").remove() 
    eventObject.className = "occupied"
    $('#calendar').fullCalendar 'updateEvent', eventObject
    
    return
  
  return

# Функция отображает окно отмены занятия 
displayMessageCancelLesson = (eventObject) ->

  start = eventObject.start.format "h:mm A"
  end = eventObject.end.format "h:mm A"
  student = eventObject.title
  
  selectHtml = "<select class=\"form-control input-sm eventClassType\">"
  selectHtml += "<option value=\"\" #{if not eventObject.class_type then 'selected="selected"' else ''}>#{I18n.t 'calendar.type_not_defined'}</option>"
  for type of CLASS_TYPES
    selectHtml += "<option value=\"#{type}\" #{if eventObject.class_type? and parseInt(eventObject.class_type) == parseInt(type) then 'selected="selected"' else ''}>#{CLASS_TYPES[type]}</option>"
  selectHtml += "</select>"  
  
  $("#events-info").html ''
  
  deferredPaymentHtml = ''
  freeHtml = ''
  leasePaidHtml = ''
  leaseCarriedOutHtml = ''
  groupHtml = ''
  
  if eventObject.lease
    leasePaidChecked = if eventObject.paid then 'checked' else ''
    leasePaidHtml = "<div class=\"eventInfoBody__buttons\">
                        <label class=\"checkbox inline\">
                          <input type=\"checkbox\" value=\"leasePaid\" class=\"eventLeasePaid\" #{leasePaidChecked}> #{I18n.t 'calendar.paid'}
                        </label>
                    </div>"
                    
  if not eventObject.editable
    leaseCarriedOutChecked = if eventObject.carried_out then 'checked' else ''
    leaseCarriedOutHtml = "<div class=\"eventInfoBody__buttons\">
                              <label class=\"checkbox inline\">
                                <input type=\"checkbox\" value=\"leaseCarriedOut\" class=\"eventLeaseCarriedOut\" #{leaseCarriedOutChecked}> #{I18n.t 'calendar.carried_out'}
                              </label>
                          </div>"
  
#  if (not eventObject.paid and eventObject.editable) or eventObject.lease
#    freeChecked = 'checked'
#    freeHtml = "<div class=\"eventInfoBody__buttons\">
#                              <label class=\"checkbox inline\">
#                                <input type=\"checkbox\" value=\"free\" class=\"eventFree\" #{freeChecked}> #{I18n.t 'calendar.free_lesson'}
#                              </label>
#                           </div>"
                           
#    deferredPaymentChecked = if eventObject.deferred_payment then 'checked' else ''
#    deferredPaymentHtml = "<div class=\"eventInfoBody__buttons\">
#                              <label class=\"checkbox inline\">
#                                <input type=\"checkbox\" value=\"deferredPayment\" class=\"eventDeferredPayment\" #{deferredPaymentChecked}> #{I18n.t 'calendar.deferred_payment'}
#                              </label>
#                           </div>"
  
  if eventObject.editable and not eventObject.paid 
    deleteHtml = "<button type=\"button\" class=\"btn btn-xs btn-danger eventDestroy\">#{I18n.t 'general.delete'}</button>"      
  else 
    deleteHtml = "<button type=\"button\" class=\"btn btn-xs btn-danger eventDestroy\">#{I18n.t 'general.delete'}</button>"
    
  homeworkHtml = ""
  if eventObject.homework_tasks? and eventObject.homework_tasks.length
    homeworkHtml = "<div class=\"homework-panel\">
                      <div class=\"homework-title\"><a href=\"/tutor/homework/#{eventObject.id}\" class=\"homework-title__link\">#{I18n.t 'homework.homework_single'}</a></div>
                      <ul class=\"homework-list\">"          
    homeworkHtml += "   <li class=\"homework-list__element #{if task.is_done then 'homework-list__element_done'}\">#{task.title}</li>" for task in eventObject.homework_tasks
    homeworkHtml += " </ul>
                    </div>"
                    
  ondaymoveHtml = ""
  if eventObject.editable and moment(eventObject.start).format("W") is moment().format("W")
    ondaymoveHtml = "<div class=\"eventInfoBody__buttons\">
                  <button class=\"btn btn-xs btn-warning eventMoveonday\">#{'Перенос на завтра'}</button>
                </div>"

  plushourmoveHtml = ""
  if eventObject.editable and moment(eventObject.start).format("W") is moment().format("W")
    plushourmoveHtml = "<div class=\"eventInfoBody__buttons\">
                  <button class=\"btn btn-xs btn-warning eventMoveplushour\">#{'Плюс час'}</button>
                </div>"

  minushourmoveHtml = ""
  if eventObject.editable and moment(eventObject.start).format("W") is moment().format("W")
    minushourmoveHtml = "<div class=\"eventInfoBody__buttons\">
                  <button class=\"btn btn-xs btn-warning eventMoveminushour\">#{'Минус час'}</button>
                </div>"

  copyHtml = "<div class=\"eventInfoBody__buttons\">
                  <button class=\"btn btn-xs btn-success eventCopy\">#{'Повтор через 7 дней'}</button>
                </div>"

  groupChecked = 'checked'
  groupHtml = "<div class=\"eventInfoBody__buttons\">
                <label class=\"checkbox inline\">
                  <input type=\"checkbox\" value=\"group\" class=\"eventGroup\" #{groupChecked}> #{I18n.t 'calendar.group_class'}
                </label>
              </div>"
    
  html = "<div class=\"panel panel-default eventInfoBlock\">
              <div class=\"panel-body eventInfoBody\">
                <div class=\"eventInfoBody__text\">
                  #{I18n.t 'calendar.lesson_with_student_on_time', {start: start, end: end, student: student}}
                </div>                
                #{selectHtml}<br/>
                #{homeworkHtml}
                #{leasePaidHtml}
                #{leaseCarriedOutHtml}
                #{freeHtml}
                #{deferredPaymentHtml}
                #{groupHtml}
                #{ondaymoveHtml}
                #{copyHtml}
                #{plushourmoveHtml}
                #{minushourmoveHtml}
                <div class=\"eventInfoBody__buttons\">
                  #{deleteHtml}
                  <button type=\"button\" class=\"btn btn-xs btn-default eventWindowClose\">#{I18n.t 'general.close'}</button>
                </div>
              </div>
          </div>"
  $("#events-info").append html  
    
  $(".eventInfoBlock .eventWindowClose").click ->
    $(this).closest(".eventInfoBlock").remove()
    return
    
  $(".eventClassType").change ->
    eventObject.class_type = $(".eventClassType").val()
    editSchedule eventObject
    return
     
  $(".eventInfoBlock .eventDestroy").click ->
    return unless confirm "#{I18n.t 'calendar.delete_confirmation'}"
    destroySchedule eventObject
    $(this).closest(".eventInfoBlock").remove()
    return
    
  $(".eventDeferredPayment").click ->
    eventObject.deferred_payment = if $(this).prop "checked" then true else false
    eventObject.free = false
    eventObject.className = if $(this).prop "checked" then "deferred_payment" else "occupied"
    $('#calendar').fullCalendar 'updateEvent', eventObject  
    editSchedule eventObject
    
  $(".eventMoveonday").click ->
    eventObject.start = moment(eventObject.start).add(1, 'days')
    eventObject.end = moment(eventObject.end).add(1, 'days')
    $('#calendar').fullCalendar 'updateEvent', eventObject  
    editSchedule eventObject

  $(".eventMoveplushour").click ->
    eventObject.start = moment(eventObject.start).add(1, 'hours')
    eventObject.end = moment(eventObject.end).add(1, 'hours')
    $('#calendar').fullCalendar 'updateEvent', eventObject  
    editSchedule eventObject

  $(".eventMoveminushour").click ->
    eventObject.start = moment(eventObject.start).add(-1, 'hours')
    eventObject.end = moment(eventObject.end).add(-1, 'hours')
    $('#calendar').fullCalendar 'updateEvent', eventObject  
    editSchedule eventObject

  $(".eventCopy").click ->
    eventObject.start = moment(eventObject.start).add(1, 'weeks')
    eventObject.end = moment(eventObject.end).add(1, 'weeks')
    $('#calendar').fullCalendar 'updateEvent', eventObject  
    addSchedule eventObject
    
  $(".eventFree").click ->
    eventObject.free = true
    eventObject.deferred_payment = false
    eventObject.className = if $(this).prop "checked" then "free" else "occupied"
    $('#calendar').fullCalendar 'updateEvent', eventObject      
    editSchedule eventObject
    
  $(".eventLeasePaid").click ->
    eventObject.lease_paid = if $(this).prop "checked" then true else false
    eventObject.free = false
    eventObject.deferred_payment = false
    eventObject.className = if $(this).prop "checked" then "paid" else "occupied"
    $('#calendar').fullCalendar 'updateEvent', eventObject      
    editSchedule eventObject
    
    $(".eventDeferredPayment").prop "checked", false    
    if $(this).prop "checked" 
      $(".eventDeferredPayment").prop "disabled", true
    else
      $(".eventDeferredPayment").prop "disabled", false
    
  $(".eventLeaseCarriedOut").click ->
    eventObject.carried_out = if $(this).prop "checked" then true else false
    eventObject.className = if $(this).prop "checked" then "elapsed" else "missed"
    $('#calendar').fullCalendar 'updateEvent', eventObject  
    editSchedule eventObject
    
  $(".eventGroup").click ->
    eventObject.group = true
    $('#calendar').fullCalendar 'updateEvent', eventObject      
    editSchedule eventObject

  return
  
setTimeline = (view) ->
  return unless view
  parentDiv = $('.fc-slats:visible').parent()
  return if parentDiv.length == 0
  
  timeline = parentDiv.children('.timeline')
  if timeline.length == 0
    timeline = $('<hr>').addClass('timeline')
    parentDiv.prepend timeline
    
  if not @calendarTimezone? or @calendarTimezone is 'local'
    curTime = moment()
  else
    curTime = moment.tz moment(), @calendarTimezone
    
  if view.intervalStart.unix() < $.fullCalendar.moment().unix() and view.intervalEnd.unix() > $.fullCalendar.moment().unix()
    timeline.show()
  else
    timeline.hide()
    return
    
  curSeconds = curTime.hours() * 60 * 60 + curTime.minutes() * 60 + curTime.seconds()
  percentOfDay = curSeconds / 86400
  
  topLoc = Math.floor(parentDiv.height() * percentOfDay)
  timeline.css 'top', topLoc + 'px'
  if view.name == 'agendaWeek'
    dayCol = $('.fc-today:visible')
    left = dayCol.position().left + 1
    width = dayCol.width() - 2
    timeline.css
      left: left + 'px'
      width: width + 'px'
  return  
  
getTimeWithCorrectTimezone = (time) ->
  return time if not @calendarTimezone? or @calendarTimezone is 'local'
  newTime = time.clone()
  newTime = moment.tz newTime, @calendarTimezone
  newTime.add(time.utcOffset() - newTime.utcOffset(), 'minutes')
  return newTime  

$('#filter_timezone').change ->
  changeTimezone $(this).val()
renderCalendar()  

