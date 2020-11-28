class ChatMessageFileUploader < CarrierWave::Uploader::Base
  
  CarrierWave::SanitizedFile.sanitize_regexp = /[^[:word:]\.\-\+]/
  
  storage :file
  
  def filename
     "#{secure_token}.#{file.extension}" if original_filename.present?
  end
  
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{model.sender_id}"
  end
  
  protected
  def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) or model.instance_variable_set(var, SecureRandom.uuid)
  end
  
end