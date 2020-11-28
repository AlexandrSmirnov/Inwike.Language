module ServicesHelper
  
  def move_root_services_to_end(services)
    root_services = services.select { |service| !service.services_category }    
    root_services.each do |service|
      services.delete(service)
      services << service
    end
  end
  
  def expand_services(services)
    return [] if services.empty?        
    
    #move_root_services_to_end(services)    
    
    expanded = {}
    services.each do |service|
      if service.services_category
        category = "category_#{ service.services_category.id }"
        unless expanded.has_key?(category)
          services_category = service.services_category.as_json
          expanded[category] = services_category.merge({ :services => [] })
        end
                
        expanded[category][:services] << service
      else
        expanded["service_#{ service.id }"] = service
      end
    end    
    
    expanded
  end
  
  def translate_service(service, param)
    param = "#{param}_#{I18n.locale}" if (I18n.locale != 'ru') && service["#{param}_#{I18n.locale}"].present?
    service[param.to_s]
  end
    
end
