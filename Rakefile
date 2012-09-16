$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib")

namespace :db do
  task :environment do
    require 'active_record'
    require 'db/connect'
  end

  task :setup => [:schema, :seed] do
  end

  task :schema => :environment do
    load 'db/schema.rb'
  end

  task :seed => :environment do
    require 'db/seeds'
  end
end


