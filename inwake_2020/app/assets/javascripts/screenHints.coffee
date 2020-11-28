class @ScreenHint

  # Конструктор класса, получает содержимое подсказки
  constructor: (@html) ->
  
  # Функция отображает подсказку в фиксированном месте экрана
  showInFixedPlace: (@position, options) ->
    @.setOptions options
    setTimeout (=>
      @.display()
      return
    ), @options.delay
    return
    
  setOptions: (_options) ->  
    options = 
      animation: ''
      delay: 0
      hideOnClick: true
      hideOnKeyPress: true
      
    @options = $.extend {}, options, _options
    return
    
  display: ->             
    hintClass = if @position.left then 'hint-block__left' else 'hint-block__right'
    $('body').append "<div class=\"hint-fader\"></div>"
    $('body').append "<div class=\"hint-block hint-block__fixed #{hintClass} #{@options.animation}\">#{@html}</div>"
    
    $('.hint-block').css 'top', @position.top
    
    if @position.left
      left = if /%/.test @position.left then @position.left else @position.left + 100
      $('.hint-block').css 'left', left
    else  
      right = if /%/.test @position.right then @position.right else @position.right + 100
      $('.hint-block').css 'right', right
    
    $('.hint-fader').fadeIn( =>    
      if @options.delay
        $('.hint-block').show()
      else
        $('.hint-block').fadeIn()    
    )      
    
    if @options.animation
      wow = new WOW {boxClass: 'hint-block', animateClass: 'animated'}
      wow.init()
    
    if @options.hideOnClick
      $('.hint-fader').click =>
        @.close()
        return
      
    if @options.hideOnKeyPress  
      $('body').keypress (event) =>
        @.close()
        return
      
    return
    
  close: ->
    setTimeout (=>
      $('.hint-fader, .hint-block').stop().fadeOut ->
        $(this).remove()
        return
    ), @options.delay
    return
    