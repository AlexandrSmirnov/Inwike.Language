class BreadcrumbsBuilder < BreadcrumbsOnRails::Breadcrumbs::Builder
  def render    
    class_name = 'breadcrumbs'
    if @options[:class_main]
      class_name << ' ' + @options[:class_main] 
    end
    
    @context.content_tag(:ul, class: class_name) do
      @elements.collect do |element|
        render_element(element)
      end.join.html_safe
    end
  end
 
  def render_element(element)    
    current = @context.current_page?(compute_path(element))

    class_name = 'breadcrumb'
    if @options[:class_postfix]
      class_name << ' breadcrumb_' + @options[:class_postfix] 
    end
 
    @context.content_tag(:li, :class => (class_name)) do
      link_class_name = 'breadcrumb__link'
      if @options[:class_postfix]
        link_class_name << ' breadcrumb__link_' + @options[:class_postfix] 
      end
      @context.link_to_unless_current(compute_name(element), compute_path(element), element.options.merge({:class => link_class_name}))
    end
  end
end