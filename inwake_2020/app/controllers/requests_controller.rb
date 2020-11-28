class RequestsController < ApplicationController
  
  def create
    class_request = Request.new(request_params)
    class_request.ip = request.remote_ip
    
    result = 0
    subjects = nil
    aims = nil
    tutor_traits = nil
    days = ''      

    if params[:request][:subjects] && params[:request][:subjects].kind_of?(Array)
      params[:request][:subjects].reject! { |element| element.blank? }
      params[:request][:subjects].each { |element| render :nothing => true and return unless Request::SUBJECTS_EGE.include?(element) }
      subjects = params[:request][:subjects].join(", ") 
    end  

    if params[:request][:aims] && params[:request][:aims].kind_of?(Array)
      params[:request][:aims].reject! { |element| element.blank? }
      params[:request][:aims].each { |element| render :nothing => true and return unless (Request::AIMS.include?(element) || Request::AIMS_EGE.include?(element)) }
      aims = params[:request][:aims].join(" \n") 
    end  

    if params[:request][:tutor_traits] && params[:request][:tutor_traits].kind_of?(Array)
      params[:request][:tutor_traits].reject! { |element| element.blank? }
      params[:request][:tutor_traits].each { |element| render :nothing => true and return unless (Request::TUTOR_TRAITS.include?(element) || Request::TUTOR_TRAITS_EGE.include?(element)) }
      tutor_traits = params[:request][:tutor_traits].join(" \n") 
    end 

    if params[:request][:days] && params[:request][:days].kind_of?(Hash)
      params[:request][:days].each do |key, values|
        values.reject! { |element| element.blank? }
        next if values.count.zero?
        time_array = []
        values.each { |time| if Request::TIME.include?(time.to_sym) then time_array << Request::TIME[time.to_sym] end }
        days << "#{Request::DAYS[key.to_sym][:title]} (#{time_array.join(", ")}) \n"
      end
    end 
    
    class_request.subjects = subjects
    class_request.aims = aims
    class_request.tutor_traits = tutor_traits
    class_request.days = days
      
    if class_request.save
      User.register_from_request class_request
      class_request.notify_admin 
      result = 1
    end
    
    render :json => { :result => result }
  end
    
  def request_params
    params.required(:request).permit(:name, :email, :phone, :comments, :communication)
  end
end
