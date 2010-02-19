require 'rubygems'
require 'yajl'
require 'set'
require 'redis'

require File.dirname(__FILE__) + "/remodel/entity.rb"
require File.dirname(__FILE__) + "/remodel/error.rb"

module Remodel

  def self.redis
    @redis ||= Redis.new
  end
  
end

