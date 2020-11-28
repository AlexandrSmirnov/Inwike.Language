@updateFilter = ->
  query = $('#filter-form').formSerialize()
  window.history.replaceState "object or string", "Lang", "tutors?#{query}"
  
  $('#filter-form').ajaxSubmit
    success: (response) ->
      html = $.parseHTML response
      data = $('.tutors-container', html).html()
      $('.tutors-container').html data
      return
    error: ->
      alert 'error'
      return  
  return true
    
  
@loadMoreTutors = (element) ->
  $.ajax
    url: $(element).attr 'href'
    success: (response) =>  
      html = $.parseHTML response
      data = $('.tutors-list', html).html()
      $('.tutors-list').append data
      
      if $('#load-more-tutors', html).length
        $('#load-more-tutors').attr('href', $('#load-more-tutors', html).attr 'href')
      else
        $('#load-more-tutors').remove()
      return false
    error: ->
      alert("Error!")
      return false  
  return false