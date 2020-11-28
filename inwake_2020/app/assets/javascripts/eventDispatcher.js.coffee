class @EventsDispatcher
 
  bind: (event_name, callback) ->
    @callbacks = {} unless @callbacks
    @callbacks[event_name] ||= []
    @callbacks[event_name].push callback
    @    
 
  bindOnce: (event_name, callback) ->
    newCallback = =>
      callback()
      @unbind(event_name, newCallback)      
    @bind event_name, newCallback
    @        
    
  unbind: (event_name, callback = null) ->  
    @callbacks = {} unless @callbacks
    if callback
      index = @callbacks[event_name].indexOf(callback)
      if index != -1
        delete @callbacks[event_name][index]
        @callbacks[event_name].splice index, 1
      @callbacks[event_name] = null if @callbacks[event_name].length == 0
    else
      @callbacks[event_name] = null
    @
    
 
  trigger: (event_name, data) ->
    @dispatch event_name, data
    @
 
  dispatch: (event_name, data) ->
    return unless @callbacks
    chain = @callbacks[event_name]
    callback data for callback in chain if chain?