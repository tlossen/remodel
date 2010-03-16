require 'rubygems'
require 'redis'

require File.dirname(__FILE__) + "/remodel/associations.rb"
require File.dirname(__FILE__) + "/remodel/entity.rb"
require File.dirname(__FILE__) + "/remodel/mappers.rb"

module Remodel

  class Error < ::StandardError; end
  class EntityNotFound < Error; end
  class InvalidKeyPrefix < Error; end
  class EntityNotSaved < Error; end
  class InvalidType < Error; end

  def self.mapper_by_class
    @mapper_by_class ||= Hash.new(IdentityMapper.new).merge(
      String => IdentityMapper.new(String),
      Integer => IdentityMapper.new(Integer),
      Float => IdentityMapper.new(Float),
      Array => IdentityMapper.new(Array),
      Hash => IdentityMapper.new(Hash),
      Date => SimpleMapper.new(Date, :to_s, :parse),
      Time => SimpleMapper.new(Time, :to_i, :at)
    )
  end

  def self.redis
    @redis ||= Redis.new
  end
  
end

