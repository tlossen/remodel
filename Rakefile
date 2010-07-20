require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "remodel-h"
    gem.summary = "remodel variant which uses hashes"
    gem.description = "persist your objects to redis hashes."
    gem.email = "tim@lossen.de"
    gem.homepage = "http://github.com/tlossen/remodel"
    gem.authors = ["Tim Lossen"]
    gem.files.include('lib/**/*.rb')
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test
