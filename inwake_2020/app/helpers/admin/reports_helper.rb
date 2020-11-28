module Admin::ReportsHelper
  
  def get_report_link(tutor_id, start_time, end_time)
    admin_show_report_path(:filter => {
        :tutor_id => tutor_id, 
        :start => start_time, 
        :end => end_time,
        :time_interval => "#{DateTime.strptime(start_time.to_s, '%s').strftime('%Y-%m-%d')} - #{DateTime.strptime(end_time.to_s, '%s').strftime('%Y-%m-%d')}"
      }, :utf8 => "✓")
  end
end
