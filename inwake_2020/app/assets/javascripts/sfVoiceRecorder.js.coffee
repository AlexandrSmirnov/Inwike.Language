class @sfVoiceRecorder

  class sfVoiceRecorderWorker  
    recordLength = 0
    recordBuffersL = []
    recordBuffersR = []
    sampleRate = null
    
    constructor: (config) ->
      sampleRate = config.sampleRate
          
    # Функция сохраняет значения аудиосигнала в 2 массива и увеличивает счетчик длинны записи    
    record: (inputBuffer) ->
      recordBuffersL.push inputBuffer[0]
      recordBuffersR.push inputBuffer[1]
      recordLength += inputBuffer[0].length
            
    # Функция формирует аудио фрагмент в двоичный объект (blob) и передает его в виде аргумента callback функции        
    getWav: (callback, type) ->
      bufferL = @.mergeBuffers recordBuffersL, recordLength
      bufferR = @.mergeBuffers recordBuffersR, recordLength
      
      interleaved = @.interleave bufferL, bufferR
      dataview = @.encodeWAV interleaved
      audioBlob = new Blob([dataview], { type: type })
      callback audioBlob
      
    # Функция возвращает записанные значения сигнала
    getBuffer: ->
      buffers = []
      buffers.push  @.mergeBuffers(recordBuffersL, recordLength)
      buffers.push  @.mergeBuffers(recordBuffersR, recordLength)
      return buffers
      
    # Функция очищает записанные значения сигнала 
    clear: ->
      recordLength = 0
      recordBuffersL = []
      recordBuffersR = []

    # Функция возвращает одномерный массив из объектов Float32, полученный из двумерного массива
    mergeBuffers: (recBuffers, recLength) ->
      result = new Float32Array(recLength)
      offset = 0
      i = 0
      while i < recBuffers.length
        result.set recBuffers[i], offset
        offset += recBuffers[i].length
        i++
      return result
      
    # Функция возвращает массив, собранный из чередующихся элементов двух входных массивов   
    interleave: (inputL, inputR) ->
      length = inputL.length + inputR.length
      result = new Float32Array(length)
      index = 0
      inputIndex = 0
      while index < length
        result[index++] = inputL[inputIndex]
        result[index++] = inputR[inputIndex]
        inputIndex++
      return result  
      
    floatTo16BitPCM: (output, offset, input) ->
      i = 0
      while i < input.length
        s = Math.max(-1, Math.min(1, input[i]))
        output.setInt16 offset, (if s < 0 then s * 0x8000 else s * 0x7fff), true
        i++
        offset += 2
      return  
      
    writeString: (view, offset, string) ->
      i = 0
      while i < string.length
        view.setUint8 offset + i, string.charCodeAt(i)
        i++
      return  

    # Функция собирает wav файл из массива отсчетов
    encodeWAV: (samples) ->
      buffer = new ArrayBuffer(44 + samples.length * 2)
      view = new DataView(buffer)
      
      @.writeString view, 0, "RIFF"                     # RIFF identifier 
      view.setUint32 4, 36 + samples.length * 2, true   # RIFF chunk length       
      @.writeString view, 8, "WAVE"                     # RIFF type 
      @.writeString view, 12, "fmt "                    # format chunk identifier 
      view.setUint32 16, 16, true                       # format chunk length 
      view.setUint16 20, 1, true                        # sample format (raw) 
      view.setUint16 22, 2, true                        # channel count 
      view.setUint32 24, sampleRate, true               # sample rate 
      view.setUint32 28, sampleRate * 4, true           # byte rate (sample rate * block align) 
      view.setUint16 32, 4, true                        # block align (channel count * bytes per sample) 
      view.setUint16 34, 16, true                       # bits per sample 
      @.writeString view, 36, "data"                    # data chunk identifier 
      view.setUint32 40, samples.length * 2, true       # data chunk length  
      
      @.floatTo16BitPCM view, 44, samples
      return view
      

  audioСontext = null
  audioInput = null
  audioWorker = null
  node = null
  config = {}
  bufferLen = 4096
  recording = false

  constructor: ->
    return
    
  # Функция инициализирует AudioContext и UserMedia
  initUserMedia: (callback) ->
    return callback() if audioInput?
    try
      window.AudioContext = window.AudioContext or window.webkitAudioContext
      navigator.getUserMedia = navigator.getUserMedia or navigator.webkitGetUserMedia or navigator.mozGetUserMedia or navigator.msGetUserMedia
      window.URL = window.URL or window.webkitURL
      audioСontext = new AudioContext      
      @.log "AudioContext создан."
      @.log "Функция navigator.getUserMedia #{if navigator.getUserMedia then 'доступна.' else 'не доступна!'}"
    catch error
      @.log "Браузер не поддерживает веб аудио!"
    
    # Пытаемся получить доступ к микрофону пользователя
    navigator.getUserMedia
      audio: true
    , ((stream) =>
      # Перенаправляем медиапоток с микрофона в audioСontext
      audioInput = audioСontext.createMediaStreamSource stream
      @.log "Создан медиа-поток"
      @.initRecorder callback
      return
    ), (error) ->
      @.log "Нет аудио устройств! #{error}"
      return
       
  # Инициализируем механизм записи аудиоданных с микрофона     
  initRecorder: (callback) ->
    # Подключаем входящий медиапоток на системный выход по умолчанию
    audioInput.connect audioСontext.destination
    
    # Инициализируем интерфейс сбора и обработки аудиоданных, подключаем его ко входящему медиапотоку
    node = (audioСontext.createScriptProcessor or audioСontext.createJavaScriptNode).call(audioСontext, bufferLen, 2, 2)
    audioInput.connect node
    
    # Создаем объект worker, который будет сохранять аудиоданные
    audioWorker = new sfVoiceRecorderWorker
      sampleRate: audioСontext.sampleRate        
    
    # Даем worker'у команду на сохранение текущих значений аудиосигнала 
    node.onaudioprocess = (event) =>
      return unless recording
      audioWorker.record [
          event.inputBuffer.getChannelData(0)
          event.inputBuffer.getChannelData(1)
      ]
      return
    return callback()
    
  # Функция начинает запись  
  startRecord: ->
    @.initUserMedia ->
      @.log "Запись начата"
      recording = true
      return
      
  # Функция останавливает запись      
  stopRecord: ->
    @.log "Запись остановлена"
    recording = false
    return
    
  # Функция удаляет записанные данные  
  clearRecord: ->
    @.log "Записанные данные удалены"
    recording = false
    return
  
  # Функция возвращает записанный аудио фрагмент в виде двоичного объекта (blob)
  getWav: (callback, type = 'audio/wav') ->
    @.log "Запрошен wav файл..."
    audioWorker.getWav ((data) -> 
      @.log "wav файл сгенерирован "
      callback data
    ), type
    
  createPlayer: (element) ->
    @.getWav ((data) ->
      url = URL.createObjectURL data
      audioElement = document.createElement 'audio'
      audioElement.controls = true
      audioElement.src = url      
      element.appendChild audioElement
    )
    return
  
  log:(message) ->
    console.log "sfVoiceRecorder (#{$.fullCalendar.formatDate(new Date(), "HH:mm:ss")}): #{message}"  
    