require 'rubygems'
require 'redis'
require 'date'

# If available, use the superfast YAJL lib to parse JSON.
begin
  require 'yajl/json_gem'
rescue LoadError
  require 'json'
end

# Define `Boolean` -- the missing superclass of `true` and `false`.
module Boolean; end
true.extend(Boolean)
false.extend(Boolean)

# Find the `Class` object for a given class name, which can be
# a `String` or a `Symbol` (or a `Class`).
def Class.[](clazz)
  return clazz if clazz.nil? or clazz.is_a?(Class)
  clazz.to_s.split('::').inject(Kernel) { |mod, name| mod.const_get(name) }
end

require File.join(File.dirname(__FILE__), 'remodel', 'mapper')
require File.join(File.dirname(__FILE__), 'remodel', 'has_many')
require File.join(File.dirname(__FILE__), 'remodel', 'entity')
require File.join(File.dirname(__FILE__), 'remodel', 'context')
require File.join(File.dirname(__FILE__), 'remodel', 'caching_context')


module Remodel

  # Custom errors
  class Error < ::StandardError; end
  class EntityNotFound < Error; end
  class EntityNotSaved < Error; end
  class InvalidKeyPrefix < Error; end
  class InvalidType < Error; end
  class MissingContext < Error; end

  # By default, the redis server is expected to listen at `localhost:6379`.
  # Otherwise you will have to set `Remodel.redis` to a suitably initialized
  # redis client.
  def self.redis
    @redis ||= Redis.new
  end

  def self.redis=(redis)
    @redis = redis
  end

  def self.create_context(key, options = {})
    context = Context.send(:new, key)
    context = CachingContext.send(:new, context) if options[:caching]
    context
  end
  
  # Returns the mapper defined for a given class, or the identity mapper.
  def self.mapper_for(clazz)
    mapper_by_class[Class[clazz]]
  end

  # Define some mappers for common types.
  def self.mapper_by_class
    @mapper_by_class ||= Hash.new(Mapper.new).merge(
      Boolean => Mapper.new(Boolean),
      String => Mapper.new(String),
      Integer => Mapper.new(Integer),
      Float => Mapper.new(Float),
      Array => Mapper.new(Array),
      Hash => Mapper.new(Hash),
      Date => Mapper.new(Date, :to_s, :parse),
      Time => Mapper.new(Time, :to_i, :at)
    )
  end

end