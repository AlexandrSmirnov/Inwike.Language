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
    $('#filter_start').val interval[0]
    $('#filter_end').val interval[1]
    return  