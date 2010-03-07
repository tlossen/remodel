require 'rubygems'
require 'redis'

require File.dirname(__FILE__) + "/remodel/collection.rb"
require File.dirname(__FILE__) + "/remodel/entity.rb"

module Remodel

  class Error < ::StandardError; end
  class EntityNotFound < Error; end  
  class InvalidKeyPrefix < Error; end

  def self.redis
    @redis ||= Redis.new
  end
  
end

