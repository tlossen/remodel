require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "remodel"
    gem.summary = ""
    gem.description = ""
    gem.email = "tim@lossen.de"
    gem.homepage = "http://github.com/tlossen/remodel"
    gem.authors = ["Tim Lossen"]
    gem.files.include('lib/**/*.rb')
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
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

task :test => :check_dependencies
task :default => :test
