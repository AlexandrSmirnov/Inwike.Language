class Tutor < ActiveRecord::Base
  mount_uploader :photo, PhotoUploader
  belongs_to :user
  has_many :opinions
  
  has_many :service, :through => :tutor_services
  has_many :tutor_services
  
  validates :url, presence: true, uniqueness: { case_sensitive: false }
  
  DIALECTS = %w[british american]
     
  scope :filter, (lambda do |filter| 
      return if not filter
      
      key_map = {"service" => "services.id"}        
      
      filter.delete_if { |key, val| val.nil? or val.length.zero? }
      conditions = Hash[filter.map { |key, val| key_map.include?(key) ? [key_map[key], val] : [key, val] }] 
      
      {:include => :service, :conditions => conditions}
  end)

  
  scope :filter_ege, (lambda do |filter| 
      return if not filter
      
      key_map = {"advanced_education" => "services.advanced_education", "services_category" => "services.services_category_id"}        
            
      filter.delete("classes_group")
      filter.delete_if { |key, val| val.nil? or val.length.zero? }
      conditions = Hash[filter.map { |key, val| key_map.include?(key) ? [key_map[key], val] : [key, val] }] 
      
      {:include => :service, :conditions => conditions}     
  end)

  scope :filter_classes_group, (lambda do |filter| 
    return if not filter or not filter.include?('classes_group') or filter['classes_group'].length.zero?
    return unless Service::CLASSES_GROUPS.include?(filter['classes_group'].to_sym)
    where(["(services.classes_mask & ?) > 0", Service::CLASSES_GROUPS[filter['classes_group'].to_sym][:mask]])    
  end)
  
  scope :name_filter, (lambda do |filter| 
    return if not filter or not filter.include?('name') or filter['name'].length.zero?
    where(["tutors.name LIKE ?", "%#{filter['name']}%"])
  end)

  scope :active, -> { where("hidden IS NULL OR hidden = 0") }
  scope :recommended, (lambda do |course_id| {:include => :tutor_services, :conditions => {'tutor_services.service_id' => course_id, 'tutor_services.recommended' => true}} end)

  
  PerPage = 12
  def self.page(page)
    return self.order('tutors.sort_index ASC').offset((page.to_i-1) * PerPage).limit(PerPage)
  end
 
  def self.pages_count
    return count % PerPage == 0 ? count / PerPage : count / PerPage + 1
  end
  
  def self.get_timezones
    User.with_role('tutor').where('time_zone IS NOT NULL').uniq.pluck(:time_zone)
  end  
  
  def update(params)
    service_recommendeds = {}
    
    if params.include?('service_list')
      if params.include?('service_recommendeds')      
        params[:service_list].each { |service| service_recommendeds[service] = false }
        params[:service_recommendeds].each { |service| service_recommendeds[service] = true }
        params.delete :service_recommendeds
      end
      params.delete :service_list
    end
    
    super(params)
    update_recommendeds(service_recommendeds)    
  end
  
  def self.new(params = nil)
    service_recommendeds = {}
    
    if params && params.include?('service_list')
      if params.include?('service_recommendeds')      
        params[:service_list].each { |service| service_recommendeds[service] = false }
        params[:service_recommendeds].each { |service| service_recommendeds[service] = true }
        params.delete :service_recommendeds
      end
      params.delete :service_list
    end
    super(params)
  end
  
  def update_recommendeds(service_recommendeds)
    return true unless service_recommendeds
    
    self.tutor_services.each do |tutor_service|
      tutor_service.update({:recommended => service_recommendeds[tutor_service.service_id.to_s]}) if service_recommendeds.include?(tutor_service.service_id.to_s)
    end
    
    true
  end
  
end
