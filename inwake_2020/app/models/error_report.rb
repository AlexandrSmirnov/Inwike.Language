class ErrorReport < ActiveRecord::Base
  belongs_to :user
  
  PerPage = 10
  def self.page(page)
    return self.offset((page.to_i-1) * PerPage).limit(PerPage)
  end
 
  def self.pages_count
    return count % PerPage == 0 ? count / PerPage : count / PerPage + 1
  end
  
  mount_uploader :file, FileUploader
end
