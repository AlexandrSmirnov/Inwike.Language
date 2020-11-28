class MessageFile
  
  include Mongoid::Document
  
  field :name, :type => String
  field :path, :type => String
  field :user_id, :type => Integer
  field :size, :type => Integer
  field :time, :type => Integer
  
  mount_uploader :path, MessageFileUploader
  before_save :set_file_size
  
  private

  def set_file_size
    if path.present? && path_changed?
      self.size = path.file.size
    end
  end
  
end
