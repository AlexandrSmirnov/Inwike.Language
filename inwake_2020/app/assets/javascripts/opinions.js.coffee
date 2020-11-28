@loadMoreOpinions = (element) ->
  $.ajax
    url: $(element).attr 'href'
    success: (response) =>  
      html = $.parseHTML response
      data = $('.reviews-list', html).html()
      $('.reviews-list').append data
      
      if $('#load-more-opinions', html).length
        $('#load-more-opinions').attr('href', $('#load-more-opinions', html).attr 'href')
      else
        $('#load-more-opinions').remove()
      return false
    error: ->
      alert("Error!")
      return false  
  return false