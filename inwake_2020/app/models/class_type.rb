class ClassType < ActiveRecord::Base
  has_many :schedule
  has_many :tutors, :through => :tutor_classes
  has_many :tutor_classes
  
  after_destroy { |class_type| class_type.tutor_classes.destroy_all }
end
