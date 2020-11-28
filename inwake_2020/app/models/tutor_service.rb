class TutorService < ActiveRecord::Base
  belongs_to :tutor
  belongs_to :service
end
