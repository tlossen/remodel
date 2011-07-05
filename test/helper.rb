require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'mocha'

require File.dirname(__FILE__) + '/../lib/remodel.rb'

class Test::Unit::TestCase

  def redis
    Remodel.redis
  end
  
  def context
    @context ||= Remodel.create_context('test')
  end
  
end
