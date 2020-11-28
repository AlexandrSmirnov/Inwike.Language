class TutorClass < ActiveRecord::Base
  belongs_to :user
  belongs_to :class_type
end
