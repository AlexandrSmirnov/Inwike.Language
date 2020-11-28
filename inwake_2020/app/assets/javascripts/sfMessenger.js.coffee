class @sfMessenger

  # Класс sfMessage описывает отдельное сообщение в чате
  class sfMessage  
  
    constructor: (@list, @socket, @id, @text, @time, @delivered, @own, @senderName = null, @removed = false, @edited = false) ->
      @element = null
      
    # Функция меняет значение delivered для сообщения и изменяет html отображение сообщения
    update: (@delivered, @removed = false, @text, @edited = false) ->
      return if not @element?
      @element.replaceWith @.createElement()
      
    # Отправляет сообщение на сервер  
    send: (sender, recipient) ->
      message = {
        message: @text,
        recipient_id: recipient,
        sender_id: sender,
        time: @time,
        id: @id
      }
      @socket.trigger 'send_chat_message', message      
      
    # Удаляет сообщение 
    remove: ->
      if confirm "#{I18n.t 'lesson.delete_confirmation'}"
        @socket.trigger 'remove_chat_message', @id
        return
        
    # Отображает форму редиктирования
    edit: ->
      $('#chatMsg').val @text
      $('#chatMsg').addClass "editing"
      $('#sendMsgButton').hide()
      $('#saveMsgButton, #cancelMsgButton').show()
      
      switchOffEditing = ->
        $('#chatMsg').val ''
        $('#chatMsg').removeClass "editing"
        $('#sendMsgButton').show()
        $('#saveMsgButton, #cancelMsgButton').hide()
        
      $('#cancelMsgButton').unbind 'click'
      $('#cancelMsgButton').click =>
        switchOffEditing()
        
      $('#saveMsgButton').unbind 'click'
      $('#saveMsgButton').click =>
        message = {
          message: $('#chatMsg').val(),
          id: @id
        }
        @socket.trigger 'edit_chat_message', message   
        switchOffEditing()
                    
    # Убирает html-теги  
    removeTags: (text) ->
      return '' if not text?
      text.replace(/<\/?[^>]+>/gi, '')
      
    # Возвращает текст сообщения
    getText: ->
      autolinker = new Autolinker
      text = @.removeTags(@text).replace(new RegExp('\r?\n','g'), '<br />')
      autolinker.link text
      
    # Возвращает название класса сообщения
    getClassName: ->  
      if @own
        className = if @delivered then "left" else "left not-delivered"
      else
        className = "right"
      className 
      
    # Возвращает html код кнопок удаления и редактирования сообщения
    getButtons: ->
      return '' if not @own or @removed
      "<span class=\"buttons\">
        <a href=\"#\" onclick=\"$(this).closest('.chatMsg').data('object').remove(); return false;\"><i class=\"fa fa-trash-o\"></i></a>
        <a href=\"#\" onclick=\"$(this).closest('.chatMsg').data('object').edit(); return false;\"><i class=\"fa fa-pencil-square-o\"></i></a>
      </span>"
      
    # Возвращает html код сообщения
    getHtml: ->          
      "<li class=\"chatMsg #{@.getClassName()}\" data-id=\"#{@id}\" data-time=\"#{@time}\" onclick=\"$(this).data('object').goTo();\">
          <span class=\"time\">#{moment(@time).format 'HH:mm:ss'}</span>
          <span class=\"message\">
            #{if @removed then "<span class=\"removed\">#{I18n.t 'lesson.message_removed'}</span>" else @.getText()}      
            #{@.getButtons()}     
            #{if @edited and not @removed then "<span class=\"edited\" title=\"#{I18n.t 'lesson.message_edited'}\"><i class=\"fa fa-pencil\"></i></span>" else ''}    
          </span>
        </li>" 
        
    # Создает объект dom и возвращает его    
    createElement: ->
      @element = $(@.getHtml())
      @element.data 'object', @
      @element
      
    # Возвращает true, если оба значения timestamp указывают на один и тот же день, иначе - false  
    dateEquals: (date1, date2) ->
      return true if moment(date1).format('DD.MM.YYYY') is moment(date2).format('DD.MM.YYYY')
      return false  
      
    # Создает html объект сообщения в конце чата  
    show: ->
      @.showAfter $('#chat-label-typing').prev()
      
    # Создает html объект сообщения в начале чата  
    showFirst: ->
      @.showAfter $('#chat-label-loading')
      
    # Создает html объект сообщения после другого заданного сообщения
    showAfterMessage: (message) ->
      return if not message.element?
      @.showAfter message.element
      
    # Создает html объект сообщения после заданного html элемента
    showAfter: (element) ->
      element.after @.createElement()
      $('#chat-label-no-messages').hide()
      @.showDateLabel() if element.hasClass('chat-label') or (element.data('time')? and not @.dateEquals(element.data('time'), @.time))

    # Создает элемент, содержащий дату сообщения, и помещает его перед сообщением
    showDateLabel: ->
      date = moment(@time).format 'DD-MM-YYYY'
      $(".chat-date-label-#{date}").remove()
      @element.before "<li class=\"chat-date chat-date-label-#{date}\"> #{moment(@time).format 'DD-MM-YYYY'} </li>"    
      
    # Показывает всплывающее уведомление
    notify: ->
      $.gritter.add
        title: 'Message'
        text: @.getText()
        sticky: false
        time: ''
        
    #
    containsText: (search) ->
      return true if @text.search(new RegExp(search, "i")) > -1
      false
      
    #
    goTo: () ->
      @list.scrollToTime @time

  # Класс sfMessageFile описывает сообщение, представляющее собой загруженный файл
  class sfMessageFile extends sfMessage
  
    constructor: (@list, @socket, @id, @filename, @fileSize, @time, @delivered, @own, @senderName = null, @removed = false) ->
      @element = null
      
    formatFileSize: (size) ->
      return "#{size} #{I18n.t 'general.infUnits.byte'}" if(size < 1024)
      return "#{(size/1024).toFixed(1)} #{I18n.t 'general.infUnits.kilobyte'}" if(size < 1048576)
      return "#{(size/1048576).toFixed(1)} #{I18n.t 'general.infUnits.megabyte'}"  
      
    getText: ->
      "#{I18n.t 'lesson.file_sent'} <a href=\"/user/messenger/file/#{@id}/#{@filename}\" target=\"_blank\">
        #{@filename}</a> 
       (#{@.formatFileSize @fileSize})"      
       
    getButtons: ->
      return '' if not @own or @removed
      "<span class=\"buttons\">
        <a href=\"#\" onclick=\"$(this).closest('.chatMsg').data('object').remove(); return false;\"><i class=\"fa fa-trash-o\"></i></a>
      </span>"   
      
    edit: ->
      false
       
    # Отправляет сообщение на сервер  
    @send: (form, sender, recipient) ->
      $(form).ajaxSubmit
        beforeSubmit: (formData, jqForm, options) ->
          formData.push
            name: 'message[recipient_id]'
            value: recipient
          formData.push
            name: 'message[sender_id]'
            value: sender
          formData.push
            name: 'message[time]'
            value: new Date().getTime()
        success: ->
          return
        error: ->
          alert 'error'
          return
        
    #
    containsText: (search) ->
      return true if @filename.search(new RegExp(search, "i")) > -1
      false

  # Класс sfMessagesList описывает список сообщений в чате
  class sfMessagesList
    
    constructor: (@messenger, recipient, userId, @socket, fromTime = null) ->
      console.log "sfMessagesList: объект создан"
      @messages = {}
      @recipient = parseInt(recipient)
      @userId = parseInt(userId)
      @firstTime = 0
      @lastTime = 0
      
      $('#chat .chatMsg, #chat .chat-date').remove()
      @messageSound = new Howl(urls: ["/sounds/drip.m4a"])
      @.initWebsocketEvents()
      return unless @.isLessonPageOpened()
      
      if fromTime
        @.loadMessages fromTime
      else
        @.loadLastMessages()
      
    # Функция инициализирует события websocket  
    initWebsocketEvents: ->
      @socket.unbind 'chat_message'
      @socket.bind 'chat_message', (message) =>  
        #return if (parseInt(message.sender_id) != @recipient) and (parseInt(message.sender_id) != @userId)
        @messageSound.play() if parseInt(message.sender_id) != @userId
        @.displayMessage message
        clearTimeout @typingTimeout if @typingTimeout?
        $('#chat-label-typing').hide() if parseInt(message.sender_id) != @userId
        @.scrollChatToBottom()           
        
      @socket.unbind 'update_chat_message'
      @socket.bind 'update_chat_message', (message) =>       
        @.updateMessage message
        
      @socket.unbind 'typing_chat_message'
      @socket.bind 'typing_chat_message', (message) =>       
        return if not @.isLessonPageOpened() or @recipient isnt message
        scrollBottom = $('#chat')[0].scrollHeight - $('#chat').scrollTop() - $('#chat').height()        
        $('#chat-label-typing').show()
        @.scrollChatToBottom() if scrollBottom < 200
        clearTimeout @typingTimeout if @typingTimeout?
        @typingTimeout = setTimeout((->
          $('#chat-label-typing').hide()
          return
        ), 4000)
              
    # Функция загружает последние сообщения
    loadLastMessages: ->  
      @.loadMessages null, null, =>
        @.scrollChatToBottom(0)
              
    # Функция загружает сообщения с временем отправки, которое позже чем самое последнее отображенное
    loadNextMessages: ->  
      return if not @lastTime
      @.loadMessages @lastTime, null, =>
        @.scrollChatToBottom(0)
      
    # Функция загружает предыдущие сообщения
    loadPrevMessages: ->
      chatHeight = $('#chat')[0].scrollHeight
      @.loadMessages null, @firstTime, =>
        $('#chat').scrollTop ($('#chat')[0].scrollHeight - chatHeight)
      
    # Функция осуществляет загрузку сообщений
    loadMessages: (from, to, callback) ->
      $.ajax
        url: "/user/messenger/history"
        method: 'post'
        data:
          authenticity_token: AUTH_TOKEN
          recipient: @recipient
          to_time: to if to?
          from_time: from if from?
        success: (response) =>
          $('#chat-label-loading').finish().hide()
          @.displayMessages response
          @.setScrollToTopEvent() if response.messages.length > 0
          $('#chat-label-no-messages').show() if response.messages.length == 0 and Object.keys(@messages).length == 0
          callback() if callback?
          return
        error: ->
          alert("Error!")
          false  
          
    # Функция создает сообщение с текстом и отправляет его на сервер
    createChatMessage: (text) ->
      timestamp = new Date().getTime()
      message = new sfMessage(@, @socket, "temp-#{timestamp}", text, timestamp, false, true)
      message.send @userId, @recipient
      
    # Функция создает сообщение с прекрепленными файлами и отправляет его на сервер
    createFileMessage: (form) -> 
      sfMessageFile.send form, @userId, @recipient      
                       
    # Функция отображает сообщения, которые переданы в массиве  
    displayMessages: (_messages) ->
      for i of _messages.messages
        _message = _messages.messages[i]
        @.displayMessage _message
        
    # Функция отображает одно сообщение     
    displayMessage: (_message) ->
      own = (_message.sender_id == @userId) ? true : false   
      if _message.is_file
        message = new sfMessageFile(@, @socket, _message.id, _message.file_name, _message.file_size, _message.time, _message.delivered, own, null, _message.removed)          
      else
        message = new sfMessage(@, @socket, _message.id, _message.message, _message.time, _message.delivered, own, null, _message.removed, _message.edited)
      if @recipient and (_message.sender_id == @recipient or _message.sender_id == @userId)
        @.insertMessage message
      else
        message.notify()
      
    # Функция обновляет содержимое сообщения
    updateMessage: (_message) ->
      id = _message.id
      return if not @messages[id]?
      @messages[id].update(_message.delivered, _message.removed, _message.message, _message.edited)
    
    # Функция вставляет сообщение в окно чата             
    insertMessage: (message) ->
      if message.time > @lastTime
        message.show()
      else  
        if message.time <= @firstTime
          message.showFirst()
        else
          console.log "insertBetween time #{message.time} first #{@firstTime} last #{@lastTime}"
          @.insertBetween message
      
      @messages[message.id] = message
      @firstTime = message.time if message.time < @firstTime or not @firstTime
      @lastTime = message.time if message.time > @lastTime   
      message.notify() if not @.isLessonPageOpened() 
            
    # Функция находит место для вставки сообщения, исходя из времени, и осуществляет вставку
    insertBetween: (message) ->
      return if not @.isLessonPageOpened()
      lastBefore = null      
      for id of @messages
        lastBefore = @messages[id] if @messages[id].time < message.time and (not lastBefore or lastBefore.time < @messages[id].time)
      message.showAfterMessage lastBefore      
      
    # Функция вставляет уже созданные сообщения в окно чата. Используется, если история сообщений уже была ранее загружена
    redraw: ->
      return if not @.isLessonPageOpened()
      console.log "sfMessenger: redraw"
      $('#chat .chatMsg, #chat .chat-date').remove()
      @lastTime = 0
      @firstTime = 0
      for id of @messages
        @.insertMessage @messages[id]
      $('#chat-label-loading').hide()
      $('#chat-label-no-messages').show() if Object.keys(@messages).length == 0
      @.setScrollToTopEvent()
      @.scrollChatToBottom(20)
      
    # Функция отключает автоматическую загрузку предыдущих сообщений, при прокрутке окна чата
    disableAutoload: ->  
      $('#chat').unbind 'scroll'
      
    # Функция включает автоматическую загрузку предыдущих сообщений, при прокрутке окна чата
    setScrollToTopEvent: ->
      $('#chat').unbind 'scroll'
      $('#chat').scroll (event) =>
        if $(event.target).scrollTop() is 0
          $('#chat').unbind 'scroll'
          $('#chat-label-loading').slideDown()
          @.loadPrevMessages()
            
    # Функция прокручивает окно чата вниз
    scrollChatToBottom: (delay = 0) ->
      if delay > 0
        setTimeout (->
          $('#chat').scrollTo '100%'
          return
        ), delay
      else
        $('#chat').scrollTo '100%'
        
    scrollToTime: ->
      false
      
    isLessonPageOpened: ->
      return true if (window.location.href.match /(student|tutor)\/lesson/) 
      false
            
  class sfMessagesSearchList extends sfMessagesList 
    
    #
    constructor: (@messenger, recipient, userId, @socket, @searchWord) ->
      super
    
    #
    loadMessages: (from, to, callback) ->
      $.ajax
        url: "/user/messenger/search"
        method: 'post'
        data:
          authenticity_token: AUTH_TOKEN
          recipient: @recipient
          to_time: to if to?
          from_time: from if from?
          word: @searchWord
        success: (response) =>
          $('#chat-label-loading').finish().hide()
          @.displayMessages response
          @.setScrollToTopEvent() if response.messages.length > 0
          $('#chat-label-no-messages').show() if response.messages.length == 0 and Object.keys(@messages).length == 0
          callback() if callback?
          return
        error: ->
          alert("Error!")
          false  
                                
    # Функция отображает одно сообщение     
    displayMessage: (_message) ->
      own = (_message.sender_id == @userId) ? true : false   
      if _message.is_file
        message = new sfMessageFile(@, @socket, _message.id, _message.file_name, _message.file_size, _message.time, _message.delivered, own, null, _message.removed)          
      else
        message = new sfMessage(@, @socket, _message.id, _message.message, _message.time, _message.delivered, own, null, _message.removed, _message.edited)
      if @recipient and (_message.sender_id == @recipient or _message.sender_id == @userId) and message.containsText(@searchWord)
        @.insertMessage message
      else
        message.notify()
        
    scrollToTime: (time) ->
      @messenger.scrollToTime time
        
    
  # Конструктор класса
  constructor: (@socket, @userData) ->    
    console.log "sfMessenger: объект создан"
    @typingMsgIsAllowed = true
    @searchWord = null
    
  # Инициализация  
  init: ->
    @.initInterfaceElements()
    @.initMessagesList()   
    @.initSearch()
    @.enableChat() if Object.keys(@userData.chat_users).length > 0
            
  # Функция определяет объекты интерфейса и задает обработчики событий
  initInterfaceElements: ->   
    return if not @.isLessonPageOpened() 
    @chatUserSelect = $('#chatUserSelect')
    @chatSendButton = $('#sendMsgButton')
    @chatTextarea = $('#chatMsg')
    @chatSearch = $('#chatSearch')
    @chatSearchClear = $('#chatSearchClear')
    @.setChatUsersList()
    
    # Обработчик изменения поля ввода сообщения
    @chatTextarea.off('keyup').on 'keyup', =>
      @.sendTypingMessage() 
      if @chatTextarea.val().length
        @.enableChatButton()
      else  
        @.disableChatButton()
        
    # Обработчик нажатия кнопки отправки сообщения    
    @chatSendButton.off('click').on 'click', =>
      return if not @chatTextarea.val().length
      @.createChatMessage()
      
    # Обработчик нажатия клавиши Enter для отправки сообщения   
    @chatTextarea.off('keydown').on 'keydown', (event) =>
      return if (event.charCode || event.keyCode) isnt 13 or event.shiftKey
      event.preventDefault()
      return if not @chatTextarea.val().length
      if @chatTextarea.hasClass('editing')
        $('#saveMsgButton').trigger 'click'
        return
      @.createChatMessage()    
      
    # Обработчики формы добавления файлов
    $('#file-upload-button').off('click').on 'click', ->
      $('#file-upload-input').trigger 'click'
      return false      
    $('#file-upload-input').off('change').on 'change', (event) ->
      $(event.target).closest('form').submit()    
    $('#file-upload-form').off('submit').on 'submit', (event) =>  
      @messagesList.createFileMessage event.target
      return false
    
  # Функция инициализирует список собеседников и задает обрабочик события изменения собеседника
  setChatUsersList: ->    
    @chatUserSelect.find('option').remove()
    for user of @userData.chat_users
      @chatUserSelect.append "<option value=\"#{user}\">#{@userData.chat_users[user]}</option>"
     
    @chatUserSelect.val @messagesList.recipient if @messagesList? and @messagesList.recipient > 0 
    @chatUserSelect.change =>
      @messagesList.disableAutoload()
      @messagesList = null
      @.initMessagesList()  
  
  # Функция инициализирует список сообщений
  initMessagesList: (fromTime = null) ->
    return if Object.keys(@userData.chat_users).length == 0
    
    if @messagesList? and @messagesList.recipient > 0 
      @messagesList.redraw()
    else
      @messagesList = null if @messagesList? 
      chatRecipient = if @.isLessonPageOpened() then @chatUserSelect.val() else 0
      
      if @searchWord
        @messagesList = new sfMessagesSearchList @, chatRecipient, @userData.id, @socket, @searchWord
      else
        @messagesList = new sfMessagesList @, chatRecipient, @userData.id, @socket, fromTime
      
  #
  initSearch: ->
    return if not @.isLessonPageOpened() 
    @chatSearch.val @searchWord
    @chatSearchClear.removeClass 'hidden' if @searchWord
    @chatSearchClear.off('click').on 'click', =>
      @chatSearch.val('')
      @chatSearchClear.addClass 'hidden'
      @searchWord = null      
      @messagesList.disableAutoload()
      @messagesList = null
      @.initMessagesList()   
    
    @chatSearch.off('keyup').on 'keyup', =>
      if $.trim(@chatSearch.val()).length < 3
        return if not @searchWord
        @searchWord = null
        @chatSearchClear.addClass 'hidden'
      else
        return if $.trim(@chatSearch.val()) is @searchWord
        @searchWord = $.trim @chatSearch.val()
        @chatSearchClear.removeClass 'hidden'
      
      @messagesList.disableAutoload()
      @messagesList = null
      @.initMessagesList()   
      
  # Функция создает новое сообщение и отправляет на сервер
  createChatMessage: ->
    @messagesList.createChatMessage @chatTextarea.val()
    @.clearChatTextarea()
    
  # Функция отправляет оповещение о том, что пользователь печатает в чате  
  sendTypingMessage: ->
    return if not @typingMsgIsAllowed
    @typingMsgIsAllowed = false
    @socket.trigger 'typing_chat_message', @messagesList.recipient      
    setTimeout (=>
      @typingMsgIsAllowed = true
      return
    ), 3000
    
  # Функция загружает сообщения с временем отправки, которое позже чем самое последнее отображенное
  loadNextMessages: ->  
    return if not @messagesList?
    @messagesList.loadNextMessages()
    
  # Функция отключает кнопку отправки сообщения
  disableChatButton: ->
    @chatSendButton.attr 'disabled', 'disabled'
        
  # Функция включает кнопку отправки сообщения
  enableChatButton: ->
    @chatSendButton.removeAttr 'disabled'    
    
  # Функция включает возможность отправлять сообщения
  enableChat: ->
    return if not @.isLessonPageOpened()
    @chatTextarea.removeAttr 'disabled'
    $('#file-upload-button').removeAttr 'disabled'
    @.enableChatButton() if @chatTextarea.val().length
    
  # Функция отключает возможность отправлять сообщения
  disableChat: ->
    return if not @.isLessonPageOpened()
    @chatTextarea.attr 'disabled', 'disabled'
    $('#file-upload-button').attr 'disabled', 'disabled'
    @.disableChatButton()
    
  # Функция очищает поле ввода сообщения
  clearChatTextarea: ->
    @chatTextarea.val ''
    @.disableChatButton()
        
  scrollToTime: (time) ->
    @messagesList.disableAutoload()
    @messagesList = null
    @searchWord = null
    @.initMessagesList time - 10
    @.initSearch()
    @chatSearchClear.addClass 'hidden' 
    
  isLessonPageOpened: ->
    return true if (window.location.href.match /(student|tutor)\/lesson/) 
    false