@getFreeLesson = ->
  $('html, body').animate {scrollTop: 0}
  $('.get-lesson-fader').fadeIn ->
    $('.get-lesson-modal').fadeIn()
    wow = new WOW(
      boxClass: 'get-lesson-modal'
      animateClass: 'bounce'
    )
    wow.init()
    return
  document.yandexCounter.reachGoal('request_opened') if document.yandexCounter?  
  return  
  
@closeFreeLessonForm = ->
  $('.get-lesson-modal').fadeOut ->
    $('.get-lesson-fader').fadeOut()
    return
  return  

$('.get-lesson-fader').click closeFreeLessonForm
$(document).keyup (e) ->
  closeFreeLessonForm() if e.keyCode is 27 # ESC
  return  
  
$('.get-lesson-field__checkbox_expanded').removeAttr 'checked'
$('.get-lesson-field__checkbox_expanded').click (event) ->
  label = $(event.target).siblings '.get-lesson-field__label'
  input = $(event.target).siblings '.get-lesson-field__input'
  if $(event.target).is ':checked'
    label.hide()
    input.show()
    input.focus()
  else
    input.hide()
    label.show()
  return  
  
$('.get-lesson-field__checkbox_limit').click (event) ->
  return unless $(event.target).data 'limit'
  limit = parseInt $(event.target).data('limit')
  if $(event.target).closest('.get-lesson-slide').find('.get-lesson-field__checkbox_limit:checked').length > limit
    event.preventDefault()
    alert "Можно выбрать не более #{limit}х вариантов!"
  return
  
$(".get-lesson-field__input_phone").inputmask "+7 (999) 999-99-99"
$('#request_name').change (event) ->
	$('.get-lesson-username').html $(event.target).val()

  
class sfRequestForm

  class sfRequestForm.slide
    constructor: (@element) ->
      @slideRow = @element.find '.row'
      
    minimize: ->      
      @element.find('.row').slideUp()
      @element.find('.get-lesson-text').addClass 'get-lesson-text_collapsed'
      @element.find('.get-lesson-text').click =>
        @.toggle()
        
    show: ->
      @element.slideDown()
      
    showContent: -> 
      @slideRow.slideDown() 
        
    toggle: ->
      if @slideRow.is(':hidden')
        @slideRow.slideDown()
      else
        @slideRow.slideUp()      
        
    checkFields: ->
      checkResult = true
      @element.find('input').removeClass 'get-lesson-field__input_error' 
      @element.find('input[required]').each (index, element) =>
        unless @.validateRequired $(element).val()
          checkResult = false
          $(element).addClass 'get-lesson-field__input_error'
      @element.find('input[type=email]').each (index, element) =>
        unless @.validateEmail $(element).val()
          checkResult = false
          $(element).addClass 'get-lesson-field__input_error'
      @element.find('input[type=tel]').each (index, element) =>
        unless @.validatePhone $(element).val()
          checkResult = false
          $(element).addClass 'get-lesson-field__input_error'      
      checkResult

    validateEmail: (email) ->
      expression = /^([\w-]+(?:\.[\w-]+)*)@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$/i;
      expression.test email
      
    validatePhone: (phone) ->
      expression = /^\+7\s\(\d{3}\)\s\d{3}-\d{2}-\d{2}/i;
      expression.test phone

    validateRequired: (value) ->
      return true if $.trim(value).length > 0
      false
      
  
  constructor: (@form) ->
    @slidesTotal = @form.find('.get-lesson-slide').length
    @currentSlideIndex = 0
    @slides = []
    @.initSlides()
    @.setNextButtonEvent()
    @.setIndicatorTip()
    @.setSubmitEvent()
    
  initSlides: ->
    @form.find('.get-lesson-slide').each (index, element) =>
      @slides.push new sfRequestForm.slide $(element)
      @.appendIndicator()
        
  setNextButtonEvent: ->
    @form.find('#get-lesson-next-button').click =>
      #console.log @slides[@currentSlideIndex]
      return false unless @slides[@currentSlideIndex].checkFields()
      @.increaseIndicator()
      @slides[@currentSlideIndex++].minimize()
      @slides[@currentSlideIndex].show()      
      @.setIndicatorTip()
      if @currentSlideIndex is @slidesTotal - 1
        @form.find('#get-lesson-next-button').hide()
        @form.find('#get-lesson-submit-button').html 'Отправить!'
      return false
    
  appendIndicator: ->
    @form.find('.get-lesson-indicator').append '<span class="get-lesson-indicator__element"></span> '
    
  increaseIndicator: ->
    @form.find('.get-lesson-indicator__element').eq(@currentSlideIndex).addClass 'get-lesson-indicator__element_filled'
    
  setIndicatorTip: ->
    @form.find('.get-lesson-indicator').attr 'title', "Осталось вопросов: #{@slidesTotal - @currentSlideIndex - 1}"
    
  checkSlides: ->
    for @slide in @slides
      unless @slide.checkFields()
        @slide.showContent()
        return false
    true    
    
  setSubmitEvent: ->
    @form.find('form').submit (event) =>  
      return false unless @.checkSlides()
      submitButton = $(event.target).find('button[type=submit]')
      submitButton.addClass 'request-submit-button_loading'
      submitButton.attr 'disabled', 'disabled'
      document.yandexCounter.reachGoal('request_sended') if document.yandexCounter?  
      $(event.target).ajaxSubmit
        success: (response) ->
          if response.result == 1
            #$('.get-lesson-button__link').hide()
            #$('.get-lesson-button__text').show()        
            $('.get-lesson-modal .get-lesson-content').addClass 'card-wrapper_rotated'
            $('.get-lesson-modal .get-lesson-slide').hide()
            $('.get-lesson-inline .get-lesson-form').addClass 'hidden'
            $('.get-lesson-inline .get-lesson-form-result').removeClass 'hidden'
            $('.get-lesson-promo .get-lesson-slide').addClass 'hidden'
            $('.get-lesson-promo-submit').addClass 'hidden'
            $('.get-lesson-promo .get-lesson-promo-result').removeClass 'hidden'
            return

          submitButton.removeAttr 'disabled'
          alert 'error'
          return
        error: ->
          submitButton.removeAttr 'disabled'
          alert 'error'
          return
      false    
    
$('.get-lesson-modal, .get-lesson-inline, .get-lesson-promo').each (index, element) ->
  requestForm = new sfRequestForm $(element)
  return    
   
