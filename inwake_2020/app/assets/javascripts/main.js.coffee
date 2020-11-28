new WOW().init()

$('.select').easyDropDown()
$('.select_tall').easyDropDown
  cutOff: 10
  wrapperClass: "dropdown dropdown_tall"

$(".opinions-carousel").owlCarousel
  items: 3
  itemsDesktop: [
    1000
    2
  ]
  itemsDesktopSmall: [
    900
    2
  ]
  itemsTablet: [
    600
    1
  ]
  singleItem: true
  autoHeight: true
  
$('.mobile-menu-icon').click (element) =>
  if $(element.target).hasClass('mobile-menu-icon_active')
    $(element.target).removeClass 'mobile-menu-icon_active'
    $('.nav-box').hide()
  else
    $(element.target).addClass 'mobile-menu-icon_active'
    $('.nav-box').show()
    
if (typeof $.fancybox == 'function')
  $('.fancybox-media').fancybox
    openEffect: 'none'
    closeEffect: 'none'
    helpers: 
      media: {}      
      overlay: 
        locked: false


    
$(window).scroll ->
  if $(window).scrollTop() == $(document).height() - $(window).height() 
    return unless $('.autoload').length
    $('.autoload').trigger 'click'    
  return    
		
###
$('#new_request').submit (event) ->
  submitButton = $(event.target).find('button[type=submit]')
  submitButton.prepend '<i class="fa fa-cog fa-spin"></i> '
  submitButton.attr 'disabled', 'disabled'

  $(this).ajaxSubmit
    success: (response) ->
      if response.result == 1
        $('.get-lesson-button__link').hide()
        $('.get-lesson-button__text').show()        
        $('.card-wrapper').addClass 'card-wrapper_rotated'
        return
        
      submitButton.removeAttr 'disabled'
      alert 'error'
      return
    error: ->
      submitButton.removeAttr 'disabled'
      alert 'error'
      return
  false    
###

###
jQuery(window).load(function() {
  jQuery(".loader").fadeOut();
  jQuery(".fader").delay(1000).fadeOut("slow");
})

$(window).scroll(function() {
    if ($(".navbar").offset().top > 50) {
        $(".navbar-fixed-top").addClass("top-nav-collapse");
    } else {
        $(".navbar-fixed-top").removeClass("top-nav-collapse");
    }
});

//jQuery for page scrolling feature - requires jQuery Easing plugin

$(function() {

    $('.page-scroll a').bind('click', function(event) {
        var $anchor = $(this);
        $('html, body').stop().animate({
            scrollTop: $($anchor.attr('href')).offset().top
        }, 1500, 'easeInOutExpo');
        event.preventDefault();
    });

    $('.show-contacts-link').click(function(){
        $('.contacts-section').slideDown();
        var $anchor = $(this);
        $('html, body').stop().animate({
            scrollTop: $($anchor.attr('href')).offset().top
        }, 1500, 'easeInOutExpo');
    });


});
###