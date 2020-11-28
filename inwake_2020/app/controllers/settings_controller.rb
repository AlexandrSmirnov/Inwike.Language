class SettingsController < ApplicationController
  before_filter :authenticate_user!
  layout "admin"
  
  def index
    @user = current_user
  end
  
  def update     
    @password_message = nil
    @timezone_message = nil    
    if current_user.update(user_params) 
      if user_params.has_key?(:password)
        @password_message = 'users.password_changed'
      end
      if user_params.has_key?(:time_zone)
        @timezone_message = 'users.timezone_changed'
      end
    end       
    render 'index'
  end
  
  private
  def user_params
    params.required(:user).permit(:password, :password_confirmation, :time_zone, :locale)
  end
  
end
