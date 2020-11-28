class UserMailer < ActionMailer::Base
  default from: 'info@lang.ru'
 
  def remind_email(user, message, subject)
    @message = message
    mail(to: user.email, subject: subject)
  end
 
  def homework_email(user, message)
    @message = message
    mail(to: user.email, subject: 'LANG')
  end
  
  def new_user(name, email, phone, password)
    @name = name
    @email = email
    @phone = phone
    @password = password
    
    template = Rails.configuration.project == 'my' ? 'new_user_my' : 'new_user'
    mail(to: email, subject: 'Регистрация на LANG.ru', template_name: template)    
  end
 
end