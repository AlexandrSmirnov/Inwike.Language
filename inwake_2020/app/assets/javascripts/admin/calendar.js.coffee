
# Функция определяет высоту календаря
getCalendarHeight = ->
  return 500 if $(window).height() < 500
  return $(window).height() - 280
  
# Функция устанавливает высоту календаря при изменении размеров окна  
setCalendarHeight = ->
  $('#calendar').fullCalendar 'option', 'height', getCalendarHeight()
  
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
  events: "/admin/calendar/list"  
  annotations: []   
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
  timezone: 'local'
    
  eventClick: (event, jsEvent, view) ->  
    displayMessage event
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
    
# Функция отображает информацию о занятии 
displayMessage = (eventObject) ->
  start = eventObject.start.format "h:mm A"
  end = eventObject.end.format "h:mm A"
  
  typeSelectHtml = "<select class=\"form-control eventClassType\">"
  typeSelectHtml += "<option value=\"\" #{if not eventObject.class_type then 'selected="selected"' else ''}>Тип не указан</option>"
  for type of CLASS_TYPES
    typeSelectHtml += "<option value=\"#{type}\" #{if eventObject.class_type? and parseInt(eventObject.class_type) == parseInt(type) then 'selected="selected"' else ''}>#{CLASS_TYPES[type]}</option>"
  typeSelectHtml += "</select>"  
  
  tutorSelectHtml = "<select class=\"form-control eventTutor\">"
  for tutor of TUTORS
    tutorSelectHtml += "<option value=\"#{tutor}\" #{if eventObject.user_id? and parseInt(eventObject.user_id) == parseInt(tutor) then 'selected="selected"' else ''}>#{TUTORS[tutor]}</option>"
  tutorSelectHtml += "</select>"  
  
  getStatus = ->  
    if eventObject.paid
      return "оплачено"
    if eventObject.free
      return "бесплатное занятие"
    if eventObject.deferred_payment
      return "отложенный платеж"
    return "не оплачено"
    
  getClass = ->
    if "#{eventObject.className}" is "missed"
      return "missed"
    if Math.floor(eventObject.start) + Math.floor(eventObject.duration) < Math.floor(Date.now())
      return "elapsed"
    if $('.eventFree').prop "checked"
      return "free"  
    if $('.eventDeferredPayment').prop "checked"
      return "deferred_payment"  
    return "occupied"  
      
  statusText = getStatus()    
  
  freeHtml = ''
  deferredPaymentHtml = ''
  if not eventObject.paid
    freeChecked = if eventObject.free then 'checked' else ''
    freeHtml = "<div class=\"eventInfoBody__buttons\">
                              <label class=\"checkbox inline\">
                                <input type=\"checkbox\" value=\"deferredPayment\" class=\"eventFree\" #{freeChecked}> #{I18n.t 'calendar.free_lesson'}
                              </label>
                           </div>"
                           
    deferredPaymentChecked = if eventObject.deferred_payment then 'checked' else ''
    deferredPaymentDisabled = if eventObject.free then 'disabled' else ''    
    deferredPaymentHtml = "<div class=\"eventInfoBody__buttons\">
                              <label class=\"checkbox inline\">
                                <input type=\"checkbox\" value=\"deferredPayment\" class=\"eventDeferredPayment\" #{deferredPaymentChecked} #{deferredPaymentDisabled}> #{I18n.t 'calendar.deferred_payment'}
                              </label>
                           </div>"  
           
  $("#events-info").html ''  
  html = "<div class=\"panel panel-default eventInfoBlock\">
              <div class=\"panel-body eventInfoBody\">
                <div class=\"eventInfoBody__text\">
                  #{typeSelectHtml}<br/>
                  #{tutorSelectHtml}<br/>
                  <input class=\"form-control eventSavedCost\" placeholder=\"Переопределение цены\" value=\"#{if eventObject.saved_cost? then eventObject.saved_cost else '' }\"/><br/>
                  Занятие с #{start} до #{end} <b><span id=\"status-text\">#{statusText}</span></b><br/>
                  ID: <b>#{eventObject.id}</b> <br/>
                  Ученик: <b>#{eventObject.student}</b> <br/>
                  Стоимость: <b>#{eventObject.cost}</b> <br/><br/>
                  Началось: <b>#{getFormattedDate(eventObject.real_start)}</b> <br/>
                  Закончилось: <b>#{getFormattedDate(eventObject.real_end)}</b> <br/>
                  Длительность: <b>#{getFormattedInterval(eventObject.real_duration)}</b> <br/>
                </div>
                #{freeHtml}
                #{deferredPaymentHtml}
                <div class=\"eventInfoBody__buttons\">
                  <button type=\"button\" class=\"btn btn-xs btn-default eventWindowClose\">Отмена</button>
                  <button type=\"button\" class=\"btn btn-xs btn-primary eventWindowSave\">Сохранить</button>
                </div>
              </div>
          </div>"
  $("#events-info").append html
    
  $(".eventInfoBlock .eventWindowClose").click ->
    $(this).closest(".eventInfoBlock").remove()
    return 
    
  $(".eventInfoBlock .eventWindowSave").click ->    
    eventObject.class_type = $(".eventClassType").val()
    eventObject.user_id = $(".eventTutor").val() 
    eventObject.tutor = $(".eventTutor option:selected").text()
    eventObject.deferred_payment = if $(".eventDeferredPayment").prop "checked" then true else false
    eventObject.free = if $(".eventFree").prop "checked" then true else false
    eventObject.className = getClass()
    eventObject.title = "#{eventObject.tutor} - #{eventObject.student}"
    eventObject.saved_cost = if parseFloat($(".eventSavedCost").val())? then $(".eventSavedCost").val() else null
    
    $("#status-text").html getStatus()        
    $('#calendar').fullCalendar 'updateEvent', eventObject  
    editSchedule eventObject    
    return 
            
  $(".eventFree").click ->    
    $(".eventDeferredPayment").prop "checked", false    
    if $(this).prop "checked" 
      $(".eventDeferredPayment").prop "disabled", true
    else
      $(".eventDeferredPayment").prop "disabled", false
  
  return    
  
# Функция обновляет существующее событие
editSchedule = (eventObject) =>
  return if not (eventObject.id > 0)
  
  $.ajax
    url: "#{document.location.href}/#{eventObject.id}"
    method: 'post'
    data:
      authenticity_token: AUTH_TOKEN
      _method : 'patch'
      schedule:
        deferred_payment: if eventObject.deferred_payment then true else false
        saved_cost: if eventObject.saved_cost? then eventObject.saved_cost else null
        free: if eventObject.free then true else false
        class_type_id: eventObject.class_type
        user_id: eventObject.user_id
     success: (response) =>  
      return
     error: ->
      alert("Error!")
      false
  return  
  
getFormattedDate = (time) ->
  return 'неизвестно' if not time
  moment.unix(time).format "HH:mm:ss"
  
getFormattedInterval = (time) ->  
  return 'неизвестно' if not time
  
  if time < 60
    return "#{time}с."
    
  seconds = time % 60
  minutes = Math.floor(time/60)
  
  if minutes < 60
    return "#{minutes}мин. #{seconds}с."
    
  minutes_new = minutes % 60
  hours = Math.floor(minutes/60)
  return "#{hours}ч. #{minutes_new}мин. #{seconds}с."
  