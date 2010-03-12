require 'rubygems'
require 'redis'

require File.dirname(__FILE__) + "/remodel/collection.rb"
require File.dirname(__FILE__) + "/remodel/entity.rb"
require File.dirname(__FILE__) + "/remodel/mappers.rb"

module Remodel

  class Error < ::StandardError; end
  class EntityNotFound < Error; end
  class InvalidKeyPrefix < Error; end
  class EntityNotSaved < Error; end
  class InvalidType < Error; end

  def self.redis
    @redis ||= Redis.new
  end
  
end

