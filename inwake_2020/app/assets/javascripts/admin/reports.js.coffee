$('#filter_time_interval').dateRangePicker
  format: "YYYY-MM-DD"
  separator: " - "
  language: I18n.locale
  startOfWeek: I18n.t 'first_week_day_text'
  getValue: ->
    return
  setValue: (val) ->
    $('#filter_time_interval').val val    
    interval = val.split(' - ')    
    from_time = moment("#{interval[0]}T00:00:00+00:00").unix()
    to_time = moment("#{interval[1]}T00:00:00+00:00").unix() + 24*60*60 - 1
    $('#filter_start').val from_time
    $('#filter_end').val to_time
    setActiveTutors from_time, to_time
    return  

setActiveTutors = (start, end) ->  
  $.ajax
    url: "/admin/reports/get_tutors_list"
    method: 'get'
    data:
      start: start
      end: end
    success: (response) =>  
      $('#filter_tutor_id option:not(:first)').remove()
      $('#filter_tutor_id').append "<option value=\"#{id}\">#{name}</option>"for id, name of response
      return
    error: ->
      alert("Error!")
      false
  
$('.report_export_flag').click (event) ->
  value = if $(event.target).is(':checked') then 1 else 0
  $("##{$(event.target).attr('id')}_hidden").val value