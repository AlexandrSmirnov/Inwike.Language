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
    editable: false
    droppable: false
    disableResizing: true
    defaultView: 'agendaWeek'
    allDaySlot: false
    events: "/student/calendar/list"  
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
    eventOverlap: false  
    timezone: timezone

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
  
  if eventObject.paid
    paidText = " (оплачено)"
    paidHtml = ""
  else if eventObject.lease and not eventObject.lease_payment_enabled
    paidText = " (не оплачено)"
    paidHtml = ""    
  else  
    paidText = ""
    paidHtml = if not eventObject.free then "<div class=\"eventInfoBody__buttons\">
                  <a href=\"/student/payments/#{eventObject.id}/create\" class=\"btn btn-xs btn-warning\" target=\"_blank\">Оплатить (<b>#{eventObject.cost} Р</b>)</a>
                </div>" else ""         
      
  homeworkHtml = ""  
  if eventObject.homework_tasks? and eventObject.homework_tasks.length
    homeworkHtml = "<div class=\"homework-panel\">
                      <div class=\"homework-title\"><a href=\"/student/homework/#{eventObject.id}\" class=\"homework-title__link\">#{I18n.t 'homework.homework_single'}</a></div>
                      <ul class=\"homework-list\">"          
    homeworkHtml += "   <li class=\"homework-list__element #{if task.is_done then 'homework-list__element_done'}\">#{task.title}</li>" for task in eventObject.homework_tasks
    homeworkHtml += " </ul>
                    </div>"  
  
  $("#events-info").html ''  
  html = "<div class=\"panel panel-default eventInfoBlock\">
              <div class=\"panel-body eventInfoBody\">
                <div class=\"eventInfoBody__text\">Занятие с #{start} до #{end}#{paidText}</div>
                #{homeworkHtml}
                #{paidHtml}
                <div class=\"eventInfoBody__buttons\">
                  <button type=\"button\" class=\"btn btn-xs btn-default eventWindowClose\">Закрыть</button>
                </div>
              </div>
          </div>"
  $("#events-info").append html
    
  $(".eventInfoBlock .eventWindowClose").click ->
    $(this).closest(".eventInfoBlock").remove()
    return
      
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
  
$('#filter_timezone').change ->
  changeTimezone $(this).val()
  
renderCalendar()    
  