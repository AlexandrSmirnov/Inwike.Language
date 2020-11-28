logStorage = store.namespace 'logger'
logStorage.session.clearAll()    

wbbOpt = 
  lang: I18n.locale
  buttons: "bold,italic,underline,|,img,video,link,|,bullist,numlist,|,removeFormat"
  
isCyclic = (obj) ->
  detect = (obj) ->
    if obj and typeof obj is "object"
      return true  if seenObjects.indexOf(obj) isnt -1
      seenObjects.push obj
      for key of obj
        if obj.hasOwnProperty(key) and detect(obj[key])
          #console.log obj, "cycle at " + key
          return true
    false
  seenObjects = []
  detect obj

getClientInfo = ->
  userAgent: navigator.userAgent
  screen: "overall: #{screen.width}x#{screen.height}, available: #{window.screen.availWidth}x#{window.screen.availHeight}"
  systemTime: moment().format()

addToLog = (type, text) ->
  logStorage.session.set logStorage.session.size(), 
    type: type
    time: Date.now()
    text: if isCyclic text then '[Cyclic object]' else text
    
isLessonPageOpened = ->
    return true if (window.location.href.match /(student|tutor)\/lesson/) 
    false    

ConsoleListener.on (type, text) ->
  addToLog type, text
  return  
  
window.onerror = (errorMsg, url, lineNumber) ->
  addToLog 'error', "Error: " + errorMsg + " Script: " + url + " Line: " + lineNumber
  return

@setReportForm = ->
  $('#new_error_report button, #new_error_report .form-description, #new_error_report .form-group').show()
  $('#new_error_report .form-message').addClass 'hidden'
  $('#new_error_report input, #new_error_report textarea').val null
  return
  
@showMenuRole = (role) ->
  $('#sidebar-left .main-menu').addClass 'hidden'
  $("#sidebar-left .main-menu[data-role=#{role}]").removeClass 'hidden'
  @role = role
  $('.dropdown-menu .menu-role').removeClass 'chosen'
  $(".dropdown-menu .menu-role[data-role=#{role}]").addClass 'chosen'
  
setMenuRole = ->
  return if $('#sidebar-left .main-menu').length < 2
  unless @role?
    @role = $('#sidebar-left .main-menu').eq(0).data 'role'
  $('#sidebar-left .main-menu').addClass 'hidden'
  $("#sidebar-left .main-menu[data-role=#{role}]").removeClass 'hidden'
  showMenuRole @role
    
  
setMenuToggle = ->
  $('#main-menu-toggle').click (event) ->
    if $(event.target).hasClass('open')
      $(event.target).removeClass('open').addClass 'close'
      span = $('#content').attr 'class'
      spanNum = parseInt span.replace(/^\D+/g, '')
      newSpanNum = spanNum + 1
      newSpan = 'col-sm-' + newSpanNum
												
      $('#content').removeClass 'col-sm-' + spanNum
      $('#content').addClass newSpan
      $('#content').addClass 'full-radius'
      $('#sidebar-left').hide()			
    else		
      $(event.target).removeClass('close').addClass 'open'
      span = $('#content').attr 'class'
      spanNum = parseInt span.replace(/^\D+/g, '')
      newSpanNum = spanNum - 1
      newSpan = 'col-sm-' + newSpanNum

      $('#sidebar-left').fadeIn()
      $('#content').removeClass 'col-sm-' + spanNum
      $('#content').removeClass 'full-radius'
      $('#content').addClass newSpan
  return  
  
ready = =>   
  setMenuRole()
  setMenuToggle()
  $('.datatable').dataTable
    'sDom': '<\'row\'<\'col-lg-6\'l><\'col-lg-6\'f>r>t<\'row\'<\'col-lg-12\'i><\'col-lg-12 center\'p>>'
    'sPaginationType': 'bootstrap'
    'oLanguage': 'sLengthMenu': '_MENU_ records per page'

  $('.wysibb').wysibb wbbOpt
  $('#new_error_report').submit (event) ->
    inputFields = $(event.target).find('input, textarea')
    inputFields.attr 'readonly', 'readonly'

    submitButton = $(event.target).find('button[type=submit]')
    submitButton.prepend '<i class="fa fa-cog fa-spin"></i> '
    submitButton.find('button[type=submit]').attr 'disabled', 'disabled'
    
    formDescription = $(event.target).find('.form-description')
    formGroups = $(event.target).find('.form-group') 
    formMessage = $(event.target).find('.form-message') 

    $(this).ajaxSubmit
      beforeSubmit: (formData, jqForm, options) ->
        formData.push
          name: 'error_report[messages]'
          value: JSON.stringify logStorage.session.getAll()
        formData.push
          name: 'error_report[client_info]'
          value: JSON.stringify getClientInfo()
      success: ->
        submitButton.fadeOut()
        submitButton.find('i').remove()
        submitButton.removeAttr 'disabled'
        inputFields.removeAttr 'readonly'
        
        formDescription.slideUp()
        formGroups.slideUp()        
        formMessage.removeClass 'hidden'
        return
      error: ->
        submitButton.find('i').remove()
        submitButton.removeAttr 'disabled'
        inputFields.removeAttr 'readonly'
        alert 'error'
        return
    false  
  
  @.realtime ?= new sfRealtime
  @.realtime.init()   
    
  $('#main, body, html').addClass 'full_screen' if isLessonPageOpened()
  
  $('.select2').select2
    language: I18n.locale

if !!@TIMEZONE
  moment.tz.setDefault @TIMEZONE
  
$(document).ready(ready)
$(document).on('page:load', ready)
  
