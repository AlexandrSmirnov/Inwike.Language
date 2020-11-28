setClassTypeGroups = ->
  return if not $('.tutor-class-element').length  
  pattern = /^(.+),\s?(\d{2,3})\s?\D+$/
  
  typeName = ''
  groupId = 0
  firstGroupValue = 1
  $('.tutor-class-element').each (i) ->
    classTypeName = $(this).find('label').html()
    return if not pattern.test(classTypeName)
    searchArray = pattern.exec(classTypeName)
    
    if typeName isnt searchArray[1]
      typeName = searchArray[1]
      firstGroupValue = parseFloat(searchArray[2])
      groupId++
      $(this).attr 'data-first', true
      $(this).attr 'data-ratio', 1
      $(this).find('input[type=text]').change (event) => 
        updateTypes event
    else  
      $(this).attr 'data-first', false
      $(this).attr 'data-ratio', parseFloat(searchArray[2]) / firstGroupValue
      
    $(this).attr 'data-group', groupId      
    return  
  return

updateTypes = (event) ->
  element = $(event.target)
  classElement = element.closest('.tutor-class-element')
  
  return if not classElement.data('first')?
  $(".tutor-class-element[data-group=#{classElement.data 'group'}]").each (i) ->
    return if $(this).data('first') or not $(this).find('input[type=checkbox]').is(':checked')
    $(this).find("input[data-field=#{element.data('field')}]").val parseFloat(element.val()) * $(this).data('ratio')
    return
  
setClassTypeGroups()  