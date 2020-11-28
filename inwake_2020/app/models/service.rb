class Service < ActiveRecord::Base
  belongs_to :services_category
  
  has_many :tutor, :through => :tutor_services
  has_many :tutor_services
  has_many :opinions
  
  scope :on_main, -> { where(show_on_main: true) }
  
  CLASSES = %w[11 10 9 8 7 6 5]
  
  CLASSES_GROUPS = {
    :junior => {:name => 'Младшие классы', :mask => 120},
    :upper => {:name => 'Старшие классы', :mask => 7}
  }
  
  def classes=(classes)
    self.classes_mask = (classes & CLASSES).map { |r| 2**CLASSES.index(r) }.inject(0, :+)
  end

  def classes
    CLASSES.reject do |r|
      ((classes_mask.to_i || 0) & 2**CLASSES.index(r)).zero?
    end
  end

end
