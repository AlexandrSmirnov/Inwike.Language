class Opinion < ActiveRecord::Base
  belongs_to :tutor
  belongs_to :service
  
  scope :tutor_assigned, -> { where("tutor_id > 0") }
  scope :not_assigned, -> { where("tutor_id IS NULL AND service_id IS NULL") }
  
  PerPage = 8
  def self.page(page)
    return self.offset((page.to_i-1) * PerPage).limit(PerPage)
  end
 
  def self.pages_count
    return count % PerPage == 0 ? count / PerPage : count / PerPage + 1
  end
end
