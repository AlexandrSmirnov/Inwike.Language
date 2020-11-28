@toggleElement = (id) ->
  return if not id?
  
  element = $(".todo-list .todo-element[data-id=\"#{id}\"]")
  return if not element.length
  
  if element.data 'done'
    element.find('.todo-checkbox').prop 'checked', false
    element.find('.todo-title').removeClass 'todo-text_done'
    element.find('.todo-text').removeClass 'todo-text_done'
    element.data 'done', false
    updateTask id, false
  else  
    element.find('.todo-checkbox').prop 'checked', true
    element.find('.todo-title').addClass 'todo-text_done'
    element.find('.todo-text').addClass 'todo-text_done'
    element.data 'done', true    
    updateTask id, true  
  refreshHomeworkTree()
  return
  
@showHomework = (id) ->
  return if not id?
  timeslot = $(".timeslot[data-id=\"#{id}\"]")
  slotClass = timeslot.data 'class'
  oldId = $('#homework_window .box').data 'id'
  oldTimeslot = $(".timeslot[data-id=\"#{oldId}\"]")
  oldSlotClass = oldTimeslot.data 'class'
  
  $.ajax
    url: "#{document.location.href}/show/#{id}"
    method: 'get'
    success: (response) ->
      $('#homework_window').html response
      oldTimeslot.find('.timeslot-text').removeClass "timeslot-#{oldSlotClass}"
      oldTimeslot.find('.timeslot-arrow__inline').removeClass "timeslot-#{oldSlotClass}"
      oldTimeslot.find('.timeslot-time').removeClass "timeslot-#{oldSlotClass}"
      oldTimeslot.find('.timeslot-icon').removeClass "timeslot-icon_#{oldSlotClass}_active"
      
      timeslot.find('.timeslot-text').addClass "timeslot-#{slotClass}"
      timeslot.find('.timeslot-arrow__inline').addClass "timeslot-#{slotClass}"
      timeslot.find('.timeslot-time').addClass "timeslot-#{slotClass}"      
      timeslot.find('.timeslot-icon').addClass "timeslot-icon_#{slotClass}_active"
      return
    error: ->
      alert("Error!")
      false  
  return
  
  
refreshHomeworkTree = (id) ->
  id = $('#homework_window .box').data 'id'
  return if not id
    
  warningTime = if $('#homework_window .box').data('warning-time')? and $('#homework_window .box').data('warning-time') then true else false  
  totalTaskCount = $('.todo-list .todo-text').length
  doneTaskCount = $('.todo-list .todo-text_done').length
  
  if totalTaskCount == 0
    setHomeworkClass id, 'default'
    setHomeworkIcon id, 'fa-circle-o'
  else if totalTaskCount != doneTaskCount 
    if warningTime
      setHomeworkClass id, 'warning'
      setHomeworkIcon id, 'fa-exclamation'
    else
      setHomeworkClass id, 'default'
      setHomeworkIcon id, 'fa-exclamation'
  else
    setHomeworkClass id, 'success'      
    setHomeworkIcon id, 'fa-check'
  return
  
setHomeworkClass = (id, className) ->
  return if not id?
    
  timeslot = $(".timeslot[data-id=\"#{id}\"]")
  return if not timeslot
  
  oldClassName = timeslot.data 'class'  
  timeslot.find('.timeslot-text').removeClass "timeslot-#{oldClassName}"
  timeslot.find('.timeslot-arrow__inline').removeClass "timeslot-#{oldClassName}"
  timeslot.find('.timeslot-time').removeClass "timeslot-#{oldClassName}"
  timeslot.find('.timeslot-icon').removeClass "timeslot-icon_#{oldClassName}"
  timeslot.find('.timeslot-icon').removeClass "timeslot-icon_#{oldClassName}_active"
  
  timeslot.find('.timeslot-text').addClass "timeslot-#{className}"
  timeslot.find('.timeslot-arrow__inline').addClass "timeslot-#{className}"
  timeslot.find('.timeslot-time').addClass "timeslot-#{className}"
  timeslot.find('.timeslot-icon').addClass "timeslot-icon_#{className}"
  timeslot.find('.timeslot-icon').addClass "timeslot-icon_#{className}_active"
  
  timeslot.data 'class', className 
  return
  
setHomeworkIcon = (id, iconName) ->
  return if not id?
    
  timeslot = $(".timeslot[data-id=\"#{id}\"]")
  return if not timeslot
  
  icon = timeslot.find '.timeslot-icon i'
  icon.removeClass()
  icon.addClass "fa #{iconName}"
  return  
  
updateTask = (id, done) ->
  $.ajax
    url: "#{document.location.href}/#{id}"
    method: 'patch'
    data:
      _method : 'patch'
      authenticity_token: AUTH_TOKEN
      done : done
    success: (response) =>  
      return
    error: ->
      alert("Error!")
      false 
  return
  
@showArchive = ->
  $('.tabs .tab-element__link').removeClass 'tab-element__link_active'
  $('.tab-archive-link').addClass 'tab-element__link_active'
  return
  
@showActual = ->
  $('.tabs .tab-element__link').removeClass 'tab-element__link_active'
  $('.tab-actual-link').addClass 'tab-element__link_active'
  showList moment().weekday(0).unix(), moment().weekday(7).unix(), 'actual'
  return
  
$('.tab-archive-link').dateRangePicker
  format: "YYYY-MM-DD"
  endDate: moment().weekday 6
  separator: " - "
  language: I18n.locale
  startOfWeek: I18n.t 'first_week_day_text'
  batchMode: 'week'
  showShortcuts: false
  getValue: ->
    return
  setValue: (s) ->
    interval = s.split(' - ')
    fromDate = moment(interval[0], "YYYY-MM-DD").unix()
    toDate = moment(interval[1], "YYYY-MM-DD").unix()
    
    showList fromDate, toDate, 'archive'
    return  
    
showList = (fromDate, toDate, mode = 'both') ->    
  $.ajax
    url: "#{document.location.href}/list"
    method: 'get'
    data:
      start: fromDate
      end: toDate
      mode: mode
    success: (response) =>  
      $('.timeline').html response
      return
    error: ->
      alert("Error!")
      false 
  return  