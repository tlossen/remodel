require 'rubygems'
require 'redis'

# Use the superfast [YAJL][yajl] lib to parse [JSON][json], if available.
#
# [yajl]: http://github.com/brianmario/yajl-ruby
# [json]: http://json.org/
begin
  require 'yajl/json_gem'
rescue LoadError
  require 'json'
end

#### Monkey patches

# Define `Boolean` as the superclass of `true` and `false`.
module Boolean; end
true.extend(Boolean) 
false.extend(Boolean)

# Find the `Class` object for a given class name, which can be a `String` or `Symbol` (or `Class`).
def Class.[](clazz)
  return clazz if clazz.nil? or clazz.is_a?(Class)
  clazz.to_s.split('::').inject(Kernel) { |mod, name| mod.const_get(name) }
end

#### Remodel

module Remodel
  
  # By default, we expect to find the redis server on `localhost:6379` &mdash;
  # otherwise you will have to set `Remodel.redis` to a suitably initialized redis client.
  def self.redis
    @redis ||= Redis.new
  end

  def self.redis=(redis)
    @redis = redis
  end

  # Custom errors
  class Error < ::StandardError; end
  class EntityNotFound < Error; end
  class EntityNotSaved < Error; end
  class InvalidKeyPrefix < Error; end
  class InvalidType < Error; end
  
  #### Mapper

  # A mapper converts a given value into a native JSON value &mdash;
  # *nil*, *true*, *false*, *Number*, *String*, *Hash*, *Array* &mdash; via `pack`,
  # and back again via `unpack`.
  #
  # Without any arguments, `Mapper.new` returns the identity mapper, which maps every value into itself.
  # If `clazz` is set, the mapper rejects any value which is not of the given type.
  class Mapper
    def initialize(clazz = nil, pack_method = nil, unpack_method = nil)
      @clazz = clazz
      @pack_method = pack_method
      @unpack_method = unpack_method
    end
    
    def pack(value)
      return nil if value.nil?
      raise(InvalidType, "#{value.inspect} is not a #{@clazz}") if @clazz && !value.is_a?(@clazz)
      @pack_method ? value.send(@pack_method) : value
    end
    
    def unpack(value)
      return nil if value.nil?
      @unpack_method ? @clazz.send(@unpack_method, value) : value
    end
  end

  # So let's define some handy mappers for common types, and a way to look them up.
  # If no mapper is defined for a given class, the identity mapper is used.
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

  def self.mapper_for(clazz)
    mapper_by_class[Class[clazz]]
  end

  #### HasMany

  # Represents the many-end of a many-to-one or many-to-many association.
  class HasMany < Array
    def initialize(this, clazz, key, reverse = nil)
      super _fetch(clazz, key)
      @this, @clazz, @key, @reverse = this, clazz, key, reverse
    end

    def create(attributes = {})
      add(@clazz.create(attributes))
    end

    def add(entity)
      _add_to_reverse_association_of(entity) if @reverse
      _add(entity)
    end

  private

    def _add(entity)
      self << entity
      Remodel.redis.rpush(@key, entity.key)
      entity
    end

    def _remove(entity)
      delete_if { |x| x.key = entity.key }
      Remodel.redis.lrem(@key, 0, entity.key)
    end

    def _add_to_reverse_association_of(entity)
      if entity.send(@reverse).is_a? HasMany
        entity.send(@reverse).send(:_add, @this)
      else
        entity.send("_#{@reverse}=", @this)
      end
    end

    def _fetch(clazz, key)
      keys = Remodel.redis.lrange(key, 0, -1)
      values = keys.empty? ? [] : Remodel.redis.mget(keys)
      keys.zip(values).map do |key, json|
        clazz.restore(key, json) if json
      end.compact
    end
  end
  
#### Entity

  # The superclass of all persistent remodel entities.
  class Entity
    attr_accessor :key
    
    def initialize(attributes = {}, key = nil)
      @attributes = {}
      @key = key
      attributes.each do |name, value|
        send("#{name}=", value) if respond_to? "#{name}="
      end
    end
    
    def save
      @key = self.class.next_key unless @key
      Remodel.redis.set(@key, to_json)
      self
    end
    
    def reload
      raise EntityNotSaved unless @key
      initialize(self.class.parse(self.class.fetch(@key)), @key)
      instance_variables.each do |var|
        remove_instance_variable(var) if var =~ /^@association_/
      end
      self
    end

    def to_json
      JSON.generate(self.class.pack(@attributes))
    end
    
    def inspect
      properties = @attributes.map { |name, value| "#{name}: #{value.inspect}" }.join(', ')
      "\#<#{self.class.name}(#{key}) #{properties}>"
    end

    def self.create(attributes = {})
      new(attributes).save
    end
  
    def self.find(key)
      restore(key, fetch(key))
    end

    def self.restore(key, json)
      new(parse(json), key)
    end
    
#### DSL for subclasses

  protected

    def self.set_key_prefix(prefix)
      raise(InvalidKeyPrefix, prefix) unless prefix =~ /^[a-z]+$/
      @key_prefix = prefix
    end

    def self.property(name, options = {})
      name = name.to_sym
      mapper[name] = Remodel.mapper_for(options[:class])
      define_method(name) { @attributes[name] }
      define_method("#{name}=") { |value| @attributes[name] = value }
    end
    
    def self.has_many(name, options)
      var = "@association_#{name}".to_sym
      
      define_method(name) do
        if instance_variable_defined? var
          instance_variable_get(var)
        else
          clazz = Class[options[:class]]
          instance_variable_set(var, HasMany.new(self, clazz, "#{key}:#{name}", options[:reverse]))
        end
      end
    end
    
    def self.has_one(name, options)
      var = "@association_#{name}".to_sym
      
      define_method(name) do
        if instance_variable_defined? var
          instance_variable_get(var)
        else
          clazz = Class[options[:class]]
          value_key = Remodel.redis.get("#{key}:#{name}")
          instance_variable_set(var, clazz.find(value_key)) if value_key
        end
      end
      
      define_method("#{name}=") do |value|
        send("_reverse_association_of_#{name}=", value) if options[:reverse]
        send("_#{name}=", value)
      end
      
      define_method("_#{name}=") do |value|
        if value
          instance_variable_set(var, value)
          Remodel.redis.set("#{key}:#{name}", value.key)
        else
          remove_instance_variable(var) if instance_variable_defined? var
          Remodel.redis.del("#{key}:#{name}")
        end
      end; private "_#{name}="
      
      if options[:reverse]
        define_method("_reverse_association_of_#{name}=") do |value|
          if value
            association = value.send("#{options[:reverse]}")
            if association.is_a? HasMany
              association.send("_add", self)
            else
              value.send("_#{options[:reverse]}=", self)
            end
          else
            if old_value = send(name)
              association = old_value.send("#{options[:reverse]}")
              if association.is_a? HasMany
                association.send("_remove", self)
              else
                old_value.send("_#{options[:reverse]}=", nil)
              end
            end
          end
        end; private "_reverse_association_of_#{name}="
      end
    end
    
#### Helper methods

  private
  
    def self.fetch(key)
      Remodel.redis.get(key) || raise(EntityNotFound, "no #{name} with key #{key}")
    end
  
    # Each entity has its own counter to generate a sequence of keys.
    def self.next_key
      counter = Remodel.redis.incr("#{key_prefix}:seq")
      "#{key_prefix}:#{counter}"
    end
  
    # Default key prefix is the first letter of the class name, in lowercase.
    def self.key_prefix
      @key_prefix ||= name.split('::').last[0,1].downcase
    end
    
    def self.parse(json)
      unpack(JSON.parse(json))
    end
  
    def self.pack(attributes)
      result = {}
      attributes.each do |name, value|
        result[name] = mapper[name].pack(value)
      end
      result
    end
    
    def self.unpack(attributes)
      result = {}
      attributes.each do |name, value|
        name = name.to_sym
        result[name] = mapper[name].unpack(value)
      end
      result
    end
    
    # Lazy init
    def self.mapper
      @mapper ||= {}
    end
  end
    
end
