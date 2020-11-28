module ApplicationHelper

  def mobile_device
    agent = request.user_agent
    return "ios" if agent =~ /(tablet|ipad)/i
    return "android" if agent =~ /(android(?!.*mobile))/i
    return "mobile" if agent =~ /Mobile/
    return "desktop"
  end
  
  def ege?
    return true if Rails.configuration.project == 'ege'
    false
  end
  
  def request_themes
    if ege? 
      return t('main.theme_ege') 
    end
    t('main.theme')
  end
  
  def host_without_port
    request.host_with_port.sub(/:\d+/, '')
  end
  
  def title(page_title)
    content_for :title, "LANG - " + page_title.to_s
  end
  
  def h1(page_header)
    content_for :h1, page_header.to_s
  end
  
  def devide_by_columns(counter, elements, columns, &block)
    last_element = (elements - 1) / columns  
    if counter > last_element
      last_element = last_element + (last_element + 1) * (counter / (last_element + 1)).floor
      last_element = counter if elements / columns <= 1
    end
    block.call + (if counter == last_element then "</div><div class=\"col-sm-#{12 / columns}\">".html_safe end)
  end
  
end
