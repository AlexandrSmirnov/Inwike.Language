wbbOpt = 
  lang: I18n.locale
  buttons: "bold,italic,underline,|,img,video,link,|,bullist,numlist,|,removeFormat"

# Функция отображает окно добавления новой задачи
@addElement = ->
  html = "<li class=\"todo-element\">
            <input class=\"todo-input\" placeholder=\"#{I18n.t 'homework.title'}\">
            <span class=\"todo-actions\">
              <a class=\"todo-actions__button todo-add\" href=\"javascript:void(0)\"><i class=\"fa fa-plus\"></i></a>
              <a class=\"todo-actions__button todo-remove\" href=\"javascript:void(0)\"><i class=\"fa fa-times\"></i></a>
            </span>
            <textarea class=\"todo-textarea\" placeholder=\"#{I18n.t 'homework.comment'}\"></textarea>
          </li>"          
  $('.todo-empty').addClass 'hidden'        
  $('.todo-list').append html
  insertedElement = $('.todo-list .todo-element:last-child')
  
  $('html, body').stop().animate
    scrollTop: insertedElement.offset().top
  , 800, "easeInOutExpo"
  
  insertedElement.find('.todo-textarea').wysibb wbbOpt  
  insertedElement.find('.todo-remove').click (event) =>
    $(event.target).closest('.todo-element').remove()
    $('.todo-empty').removeClass 'hidden' if $('.todo-list .todo-element').length is 0
        
  insertedElement.find('.todo-add').click (event) =>
    schedule_id = $(event.target).closest('.box').data 'id'
    title = $(event.target).closest('.todo-element').find('.todo-input').val()
    text_el = $(event.target).closest('.todo-element').find('.todo-textarea')
    return if not schedule_id? or not title
    
    $.ajax
      url: "#{getCurrentUrl()}"
      method: 'post'
      data:
        authenticity_token: AUTH_TOKEN
        schedule_id: schedule_id
        title: title
        text: text_el.bbcode()        
      success: (response) ->
        if response.result
          #insertNewTask response.id, title, text_el.htmlcode()  
          #refreshHomeworkTree()
          $(event.target).closest('.todo-element').remove()
        return
      error: ->
        alert("Error!")
        false  
  return
  
# Функция удаляет задачу
@deleteElement = (id) ->
  return if not id?
  
  $.ajax
    url: "#{getCurrentUrl()}/#{id}"
    method: 'post'
    data:
      _method : 'delete'
    success: (response) =>  
      #if response.result
        #$(".todo-list .todo-element[data-id=\"#{id}\"]").remove()
        #refreshHomeworkTree()
      return
    error: ->
      alert("Error!")
      false  
  return
  
# Функция отображает окно редактирования задачи
@editElement = (id) ->
  return if not id?
  
  element = $(".todo-list .todo-element[data-id=\"#{id}\"]")
  return if not element.length
  
  title = element.find('.todo-title').html()
  text = element.find('.todo-text').html()
  html = "<li class=\"todo-element\">
            <input class=\"todo-input\" placeholder=\"#{I18n.t 'homework.title'}\" value=\"#{title}\">
            <span class=\"todo-actions\">
              <a class=\"todo-actions__button todo-update\" href=\"javascript:void(0)\"><i class=\"fa fa-floppy-o\"></i></a>
              <a class=\"todo-actions__button todo-remove\" href=\"javascript:void(0)\"><i class=\"fa fa-times\"></i></a>
            </span>
            <textarea class=\"todo-textarea\"></textarea>
          </li>"  
  element.after html        
  element.hide()
  
  element.next('.todo-element').find('.todo-textarea').wysibb wbbOpt
  element.next('.todo-element').find('.todo-textarea').htmlcode text
  
  element.next('.todo-element').find('.todo-remove').click (event) =>
    $(event.target).closest('.todo-element').remove()
    element.show()
  
  element.next('.todo-element').find('.todo-update').click (event) =>  
    title = $(event.target).closest('.todo-element').find('.todo-input').val()
    text_el = $(event.target).closest('.todo-element').find('.todo-textarea')
    return if not text?
    
    $.ajax
      url: "#{getCurrentUrl()}/#{id}"
      method: 'patch'
      data:
        _method : 'patch'
        title : title 
        text : text_el.bbcode() 
      success: (response) ->
        if response.result
          #element.find('.todo-title').html title
          #element.find('.todo-text').html text_el.htmlcode()
          $(event.target).closest('.todo-element').remove()
          element.show()
        return
      error: ->
        alert("Error!")
        false  
  return
  
  
# Функция осуществляет переключение состояний задачи (сделано/не сделано)
@toggleElement = (id) ->
  return if not id?
  element = $(".todo-list .todo-element[data-id=\"#{id}\"]")
  return if not element.length
  
  $.ajax
    url: "#{getCurrentUrl()}/#{id}"
    method: 'patch'
    data:
      _method : 'patch'
      authenticity_token: AUTH_TOKEN
      done : if element.data 'done' then false else true
    success: (response) =>  
      return
    error: ->
      alert("Error!")
      false     
  return
  
  
# Функция загружает список задач домашнего задания и отображает его в соответствующем окне
@showHomework = (id) ->
  return if not id?
  timeslot = $(".timeslot[data-id=\"#{id}\"]")
  slotClass = timeslot.data 'class'
  oldId = $('#homework_window .box').data 'id'
  oldTimeslot = $(".timeslot[data-id=\"#{oldId}\"]")
  oldSlotClass = oldTimeslot.data 'class'
  
  $.ajax
    url: "#{getCurrentUrl()}/show/#{id}"
    method: 'get'
    success: (response) ->
      window.history.replaceState "object or string", "Lang", "#{getCurrentUrl()}/#{id}"
    
      $('#homework_window').html response
      oldTimeslot.find('.timeslot-text').removeClass "timeslot-#{oldSlotClass}"
      oldTimeslot.find('.timeslot-arrow__inline').removeClass "timeslot-#{oldSlotClass}"
      oldTimeslot.find('.timeslot-time').removeClass "timeslot-#{oldSlotClass}"
      #oldTimeslot.find('.timeslot-icon').removeClass "timeslot-icon_#{oldSlotClass}_active"
      
      timeslot.find('.timeslot-text').addClass "timeslot-#{slotClass}"
      timeslot.find('.timeslot-arrow__inline').addClass "timeslot-#{slotClass}"
      timeslot.find('.timeslot-time').addClass "timeslot-#{slotClass}"      
     # timeslot.find('.timeslot-icon').addClass "timeslot-icon_#{slotClass}_active"
      return
    error: ->
      alert("Error!")
      false  
  return
  
  
# Функция добавляет новую задачу на страницу
insertNewTask = (task) ->
  checkboxHtml = ''  
  if @.realtime.userData.role is 'student'
    checkboxHtml = "<input type=\"checkbox\" class=\"todo-checkbox\" name=\"task-#{task.id}\" onchange=\"toggleElement(#{task.id});\">"       
  
  editHtml = ''
  if (@.realtime.userData.role is 'tutor') or (@.realtime.userData.role is 'student' and task.by_student)
    editHtml = "<a class=\"todo-actions__button\" href=\"javascript:editElement(#{task.id})\"><i class=\"fa fa-pencil\"></i></a>
                <a class=\"todo-actions__button\" href=\"javascript:deleteElement(#{task.id})\" class=\"todo-remove\"><i class=\"fa fa-times\"></i></a>"

  html = "<li class=\"todo-element\" data-id=\"#{task.id}\" data-done=\"#{if task.is_done then true else false}\">
            #{checkboxHtml}
            <span class=\"todo-title\">#{task.title}</span>
            <div class=\"todo-text\">#{task.text}</div>
            <span class=\"todo-actions\">
              <a class=\"todo-actions__button todo-attach-file\" href=\"javascript:attachFile(#{task.id})\"><i class=\"fa fa-paperclip\"></i></a>
              #{editHtml}
            </span>
            <div class=\"todo-files\"></div>
          </li>" 
  $('.todo-list').append html
  return
  
  
# Функция обновляет содержимое задачи
updateTask = (task) ->
  taskElement = $(".todo-list .todo-element[data-id=\"#{task.id}\"]")
  return if not taskElement.length
  
  taskElement.find('.todo-title').html task.title
  taskElement.find('.todo-text').html task.text
    
  if task.is_done
    taskElement.find('.todo-checkbox').prop 'checked', true
    taskElement.find('.todo-title').addClass 'todo-text_done'
    taskElement.find('.todo-text').addClass 'todo-text_done'
    taskElement.data 'done', true     
  else       
    taskElement.find('.todo-checkbox').prop 'checked', false
    taskElement.find('.todo-title').removeClass 'todo-text_done'
    taskElement.find('.todo-text').removeClass 'todo-text_done'
    taskElement.data 'done', false
  return
  
  
# Функция удаляет задачу со страницы
deleteTaskFromPage = (id) ->
  return if not id?
  $(".todo-list .todo-element[data-id=\"#{id}\"]").remove()
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
    url: "#{getCurrentUrl()}/list/list"
    method: 'get'
    data:
      start: fromDate
      end: toDate
      mode: mode
    success: (response) =>  
      $('.timeline').html response
      setHomeworkDiagrams()
      return
    error: ->
      alert("Error!")
      false 
  return


# Функция обновляет внешний вид значка в дереве домашних заданий 
refreshHomeworkTree = (schedule) ->
  
  setHomeworkProgress schedule.id, schedule.homework_progress   
  setHomeworkClass schedule.id, schedule.homework_class   
  setHomeworkIcon schedule.id, schedule.homework_icon   
  setHomeworkTip schedule.id, I18n.t schedule.homework_tip
  
  setHomeworkDiagrams()  
  return
  
setHomeworkClass = (id, className) ->
  return if not id?
    
  timeslot = $(".timeslot[data-id=\"#{id}\"]")
  current_schedule_id = $('.box').data 'id'
  return if not timeslot
  
  oldClassName = timeslot.data 'class'  
  timeslot.find('.timeslot-text').removeClass "timeslot-#{oldClassName}"
  timeslot.find('.timeslot-arrow__inline').removeClass "timeslot-#{oldClassName}"
  timeslot.find('.timeslot-time').removeClass "timeslot-#{oldClassName}"
  timeslot.find('.timeslot-icon').removeClass "timeslot-icon_#{oldClassName}"
  
  if current_schedule_id is id
    timeslot.find('.timeslot-arrow__inline').addClass "timeslot-#{className}"
    timeslot.find('.timeslot-text').addClass "timeslot-#{className}"
    timeslot.find('.timeslot-time').addClass "timeslot-#{className}"
  timeslot.find('.timeslot-icon').addClass "timeslot-icon_#{className}"
  
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
  
setHomeworkProgress = (id, progress) ->
  return if not id?
  
  canvasElement = $(".timeslot[data-id=\"#{id}\"] canvas")
  return if not canvasElement
    
  #canvasElement.data 'progress', Math.round(100*done/total)
  canvasElement.data 'progress', progress
  return
  
setHomeworkTip = (id, tip) ->
  return if not id?
    
  iconElement = $(".timeslot[data-id=\"#{id}\"] .timeslot-icon")
  return if not iconElement
  
  iconElement.attr 'title', tip
  return
  
setHomeworkDiagrams = ->
  $('.timeslot .timeslot-icon canvas').each (index, element) ->
    progress = $(element).data 'progress'
    return if not progress?
  
    percents = (100 - progress) / 50 - 0.5
    className = $(element).closest('.timeslot').data 'class'
    
    canvas = element.getContext '2d'
    canvas.clearRect 0, 0, element.width, element.height
    
    canvas.fillStyle = getFillColorByClassName className
    canvas.beginPath()
    canvas.arc element.width/2, element.height/2, element.width/2, 1.5*Math.PI, percents*Math.PI, true
    canvas.lineTo element.width/2, element.height/2
    canvas.fill()    
    canvas.lineWidth = 5;
    #canvas.strokeStyle = '#003300';
    #canvas.stroke();
    return

getFillColorByClassName = (className) ->
  return '#fabb3d' if className is 'warning'
  return '#78cd51' if className is 'success'    
  return '#ff5454' if className is 'danger'   
  return '#646464'
  
@showNewComment = ->
  return if not $('#commentInput').hasClass 'comments-input_inactive'

  $('#commentInput').animate
    height: "84"
  $('#commentButtons').fadeIn()
  $('#commentInput').removeClass 'comments-input_inactive'
  return
  
@hideNewComment = ->
  return if $('#commentInput').hasClass 'comments-input_inactive'

  $('#commentInput').animate
    height: "28"
  $('#commentButtons').fadeOut()
  $('#commentInput').addClass 'comments-input_inactive'
  return
  
@addComment = ->
  schedule_id = $('.box').data 'id'
  text = $('#commentInput').val()
  return if not text
  
  $.ajax
    url: "#{getCurrentUrl()}/create_comment/#{schedule_id}"
    method: 'post'
    data:
      authenticity_token: AUTH_TOKEN
      text: text   
    success: (response) ->
      $('#commentInput').val ''
      hideNewComment()
      return
    error: ->
      alert("Error!")
      false  
  
@deleteComment = (id) ->
  return if not id?  
  $.ajax
    url: "#{getCurrentUrl()}/delete_comment/#{id}"
    method: 'post'
    data:
      authenticity_token: AUTH_TOKEN
      _method : 'delete'
    success: (response) ->
      return
    error: ->
      alert("Error!")
      false   
  return   

insertComment = (comment) ->
  deleteHtml = if @.realtime.userData.id is comment.user.id then "<a href=\"javascript:deleteComment(#{comment.id})\" title=\"#{I18n.t 'general.delete'}\"> <i class=\"fa fa-times\"></i></a>" else ''
  html = "<li class=\"comments-element\" data-id=\"#{comment.id}\">
            <span class=\"comments-element__user\">#{comment.user.name}</span>
            <span class=\"comments-element__time\">#{moment.unix(comment.time).format "DD.MM.YYYY HH:mm"}</span>
            #{deleteHtml}
            <div class=\"comments-element__text\">#{comment.text}</div>
          </li>"
  $('.comments-list').prepend html        
  
deleteCommentFromPage = (id) ->
  return if not id?
  $('.comments-list').find(".comments-element[data-id=#{id}]").remove()
  
@attachFile = (id) ->
  return if not id?
  element = $(".todo-list .todo-element[data-id=\"#{id}\"]")
  return if not element.length  
  return if element.find('.todo-add-attachment').length
  
  html = "<form class=\"todo-add-attachment\" action=\"#{getCurrentUrl()}/attach_file/#{id}\" method=\"post\" enctype=\"multipart/form-data\">
            <input type=\"hidden\" name=\"authenticity_token\" value=\"#{AUTH_TOKEN}\">
            <div class=\"attachment-comment\">
              <input class=\"attachment-comment__input\" type=\"text\" placeholder=\"#{I18n.t 'homework.comment'}\" name=\"homework_file[title]\" maxlength=\"100\">               
            </div>          
            <div class=\"attachment-file\">        
              <input class=\"attachment-file__input\" type=\"text\" placeholder=\"#{I18n.t 'homework.select_file'}\" readonly><!--
              --><button class=\"attachment-file__browse btn btn-default btn-xs\" type=\"button\">#{I18n.t 'general.browse'}</button>
              <input class=\"attachment-file__selector hidden\" type=\"file\" name=\"homework_file[file]\">
            </div>
            <div class=\"attachment-buttons\">                  
              <button class=\"attachment-buttons__send btn btn-info btn-xs\" type=\"submit\">#{I18n.t 'general.send'}</button>
              <button class=\"attachment-buttons__cancel btn btn-default btn-xs\" type=\"button\">#{I18n.t 'general.cancel'}</button>  
            </div>                   
          </form>"
  element.append html
  
  element.find('.attachment-file__input, .attachment-file__browse').click (event) =>
    element.find('.attachment-file__selector').trigger 'click'
      
  element.find('.attachment-file__selector').change (event) =>
    element.find('.attachment-file__input').val $(event.target).val()
  
  element.find('.attachment-buttons__cancel').click (event) =>
    $(event.target).closest('.todo-add-attachment').remove()
    
  element.find('.todo-add-attachment').submit ->
    if not element.find('.todo-add-attachment .attachment-file__selector').val()
      return false;
    $(this).ajaxSubmit
      success: ->
        element.find('.todo-add-attachment').remove()
        return
      error: ->
        alert 'error'
        return
    false  
  return
  
@deleteFile = (id) ->
  return if not id?  
  $.ajax
    url: "#{getCurrentUrl()}/delete_file/#{id}"
    method: 'post'
    data:
      authenticity_token: AUTH_TOKEN
      _method : 'delete'
    success: (response) ->
      return
    error: ->
      alert("Error!")
      false   
  return    
  
insertFile = (homeworkFile) ->
  return if not $('.todo-list').find(".todo-element[data-id=#{homeworkFile.homework_id}]").length
  
  if @.realtime.userData.id is homeworkFile.user.id  
    title = I18n.t 'homework.attachment_hint_you_js', {time: moment.unix(homeworkFile.time).format "DD.MM.YYYY HH:mm"}
  else
    title = I18n.t 'homework.attachment_hint_other_js', {time: moment.unix(homeworkFile.time).format "DD.MM.YYYY HH:mm", username: homeworkFile.user.name}
  
  labelClass = if homeworkFile.user.is_tutor then 'warning' else 'info'
  deleteHtml = if @.realtime.userData.id is homeworkFile.user.id then "<a href=\"javascript:deleteFile(#{homeworkFile.id})\" title=\"#{I18n.t 'general.delete'}\"> <i class=\"fa fa-times\"></i></a>" else ''
  
  html = "<div class=\"todo-files_element\" data-id=\"#{homeworkFile.id}\">
            <a class=\"label label-#{labelClass}\" target=\"_blank\" href=\"#{homeworkFile.file.url}\" title=\"#{title}\"><i class=\"fa fa-file\"></i> #{homeworkFile.file.name}</a>
            <b>#{homeworkFile.title}</b>
            <i>(#{homeworkFile.file.size})</i>              
            #{deleteHtml}
          </div>"
  $('.todo-list').find(".todo-element[data-id=#{homeworkFile.homework_id}] .todo-files").append html
  
deleteFileFromPage = (id) ->  
  return if not id?  
  $('.todo-list').find(".todo-files_element[data-id=#{id}]").remove()
  
getCurrentUrl = ->
  return HOMEWORK_PATH
  
initHomework = ->
  isCurrentSchedule = (scheduleId) ->
    current_schedule_id = $('.box').data 'id'
    return false if scheduleId isnt current_schedule_id
    true
  
  @.realtime.getWebSocket().unbind 'comment-updated'
  @.realtime.getWebSocket().bind 'comment-updated', (message) ->
    return if not $('.comments-list').length
    return if not isCurrentSchedule(message.schedule.id)
        
    if message.action is 'create'
      insertComment message.comment
    
    if message.action is 'destroy'
      deleteCommentFromPage message.comment.id    
            
  @.realtime.getWebSocket().unbind 'homework-file-updated'
  @.realtime.getWebSocket().bind 'homework-file-updated', (message) =>
    return if not $('.todo-list').length
    return if not isCurrentSchedule(message.schedule.id)
    
    if message.action is 'create'
      insertFile message.homework_file
    
    if message.action is 'destroy'
      deleteFileFromPage message.homework_file.id
            
  @.realtime.getWebSocket().unbind 'homework-updated'
  @.realtime.getWebSocket().bind 'homework-updated', (message) =>
    return if not $('.todo-list').length    
    refreshHomeworkTree message.schedule 
    return if not isCurrentSchedule(message.schedule.id)
    
    insertNewTask message.homework, message.schedule if message.action is 'create'     
    updateTask message.homework if message.action is 'update'
    deleteTaskFromPage message.homework.id if message.action is 'destroy'  
  
$(document).ready =>
  setHomeworkDiagrams()
  @.realtime.ready =>
    initHomework()
  #initRecorder()
  return
  
    
###
@recorder = null
initRecorder = ->
  @recorder = new sfVoiceRecorder
  
@.startRecord = ->
  @recorder.startRecord()
  return
  
@.stopRecord = ->
  @recorder.stopRecord()
  @recorder.createPlayer(document.getElementById('audio'))
  return
  
@attachVoice = (id) ->
  return if not id?
  element = $(".todo-list .todo-element[data-id=\"#{id}\"]")
  return if not element.length  
  return if element.find('.todo-add-attachment').length
  
  html = "<form class=\"todo-add-attachment\" action=\"#{getCurrentUrl()}/attach_file/#{id}\" method=\"post\" enctype=\"multipart/form-data\">
            <input type=\"hidden\" name=\"authenticity_token\" value=\"#{AUTH_TOKEN}\">
            <div class=\"attachment-comment hidden\">
              <input class=\"attachment-comment__input\" type=\"text\" placeholder=\"Введите комментарий\" name=\"homework_file[title]\">               
            </div>          
            <div class=\"attachment-buttons\">                  
              <button class=\"attachment-buttons__send btn btn-info btn-xs hidden\" type=\"submit\">Отправить</button>
              <button class=\"attachment-buttons__record btn btn-danger btn-xs\" type=\"button\"><i class=\"fa fa-circle\"></i> Начать запись</button>  
              <button class=\"attachment-buttons__stop btn btn-default btn-xs hidden\" type=\"button\">Остановить</button>  
              <button class=\"attachment-buttons__cancel btn btn-default btn-xs\" type=\"button\">Отмена</button>  
            </div>                   
          </form>"
  element.append html  
  
  element.find('.attachment-buttons__record').click (event) =>
    $(event.target).html "<i class=\"fa fa-pause\"></i> Пауза</button> " 
    #@recorder.startRecord()
    
    
  element.find('.attachment-buttons__cancel').click (event) =>
    $(event.target).closest('.todo-add-attachment').remove()
  
  return 
  ###