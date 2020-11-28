require 'resque/tasks'  
require 'resque/scheduler/tasks'

task "resque:setup" => :environment

namespace :resque do
 task :setup do
    require 'resque'
    require 'resque-scheduler'   

    #Resque.redis = $redis
    Resque.schedule = YAML.load_file("#{Rails.root}/config/rescue_schedule.yml")
    Resque.redis.namespace = 'sf:' + Rails.configuration.project + ':' + Rails.env + ':resque'
 end
end