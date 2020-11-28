module TutorsHelper
  
  def translate_tutor(tutor, param)
    param = "#{param}_#{I18n.locale}" if (I18n.locale != 'ru') && tutor["#{param}_#{I18n.locale}"].present?
    tutor[param.to_s]
  end
  
end
