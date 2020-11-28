class Request < ActiveRecord::Base
  
  #after_create { |request| request.notify_admin }
  AIMS = [
    'Преодолеть языковой барьер',
    'Свободно общаться в путешествиях',
    'Успешно пройти собеседование на английском',
    'Расширить словарный запас',
    'Сдать сертификат (TOEFL, IELTS, GRE, Cambridge exams и т.п.)',
    'Говорить и писать грамотно (подтянуть грамматику)',
    'Улучшить произношение',
    'Общаться с коллегами из других стран',
    'Выйти замуж за иностранца'
  ]
  
  AIMS_EGE = [
    'Устранение текущих пробелов',
    'Подготовка к поступлению в ВУЗ',
    'Подготовка к экзаменам',
    'Решение нестандартных задач',
    'Углубленное изучение'    
  ]
  
  TUTOR_TRAITS = [
    'Позитивный',
    'Требовательный',
    '&laquo;С ним не заснешь!&raquo;',
    'Терпеливый',
    'С технологиями на &laquo;ты&raquo;',
    'Интересный собеседник',
    'Все &laquo;по полочкам&raquo;',
    'Много общался с носителями',
    'Умеет разговорить человека',
    'Не только кнут, но и пряник!',
    'Дает творческие задания'
  ]
  
  TUTOR_TRAITS_EGE = [
    'Позитивный',
    'Опытный',
    'Терпеливый', 
    'Дает творческие задания',
    'Требовательный',    
    'С технологиями на &laquo;ты&raquo;',
    'Все &laquo;по полочкам&raquo;',   
    'Индивидуальный подход', 
    'Умеет разговорить человека',
    'Не только кнут, но и пряник!'
  ]
  
  SUBJECTS_EGE = ['Физика', 'Математика', 'Информатика', 'Английский']
  
  DAYS = {
    :monday => {:title => 'Понедельник', :short => 'ПН'},
    :tuesday => {:title => 'Вторник', :short => 'ВТ'},
    :wednesday => {:title => 'Среда', :short => 'СР'},
    :thursday => {:title => 'Четверг', :short => 'ЧТ'},
    :friday => {:title => 'Пятница', :short => 'ПТ'},
    :saturday => {:title => 'Суббота', :short => 'СБ', :marked => true},
    :sunday => {:title => 'Воскресенье', :short => 'ВС', :marked => true}
  }
  
  TIME = {
    :morning => 'утро',
    :afternoon => 'день',
    :evening => 'вечер',
    :night => 'ночь'
  }
  
  PerPage = 10
  def self.page(page)
    return self.offset((page.to_i-1) * PerPage).limit(PerPage)
  end
 
  def self.pages_count
    return count % PerPage == 0 ? count / PerPage : count / PerPage + 1
  end
  
  def notify_admin
    self.aims = self.aims || ''
    self.tutor_traits = self.tutor_traits || ''
    self.days = self.days || ''
    
    text = "На сайте был добавлен запрос бесплатного занятия!<br/><br/>
            <b>Имя:</b> #{self.name}<br/>
            <b>Телефон:</b> #{self.phone}<br/>
            <b>Email:</b> #{self.email}<br/>
            <b>Предпочтительный способ связи:</b> #{self.communication}<br/>
            <b>Предметы:</b> #{self.subjects}<br/><br/><hr/><br/>
            
            <b>Цели:</b> <br/>
            #{self.aims.gsub(/[\r\n]+/, "<br>")}<br/><br/>

            <b>Качества преподавателя:</b> <br/>
            #{self.tutor_traits.gsub(/[\r\n]+/, "<br>")}<br/><br/>

            <b>Удобное время:</b> <br/>
            #{self.days.gsub(/[\r\n]+/, "<br>")}<br/><br/>

            <b>Комментарий:</b> <br/>
            #{self.comments}
    "
    if Rails.configuration.project == 'ege'
      title = "LANG - добавлен запрос бесплатного занятия"
    end
    
    User.send_notification_to_admins(text, title)
  end
  
end
