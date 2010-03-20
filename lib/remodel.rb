require 'rubygems'
require 'redis'
require 'yajl'

module Remodel

  class Error < ::StandardError; end
  class EntityNotFound < Error; end
  class EntityNotSaved < Error; end
  class InvalidKeyPrefix < Error; end
  class InvalidType < Error; end
  
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
  
  class HasMany < Array
    def initialize(clazz, key)
      super fetch(clazz, key)
      @clazz = clazz
      @key = key
    end
    
    def create(attributes = {})
      self << created = @clazz.create(attributes)
      redis.rpush(@key, created.key)
      created
    end

  private
  
    def fetch(clazz, key)
      keys = redis.lrange(key, 0, -1)
      values = keys.empty? ? [] : redis.mget(keys)
      keys.zip(values).map do |key, json|
        clazz.restore(key, json) if json
      end.compact
    end
    
    def redis
      Remodel.redis
    end
  end
  
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
      self.class.redis.set(@key, to_json)
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
      Yajl::Encoder.encode(self.class.pack(@attributes))
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
    
  protected

    def self.set_key_prefix(prefix)
      raise(InvalidKeyPrefix, prefix) unless prefix =~ /^[a-z]+$/
      @key_prefix = prefix
    end

    def self.property(name, options = {})
      name = name.to_sym
      clazz = find_class(options[:class])
      mapper[name] = Remodel.mapper_by_class[clazz]
      define_method(name) { @attributes[name] }
      define_method("#{name}=") { |value| @attributes[name] = value }
    end
    
    def self.has_many(name, options)
      var = "@association_#{name}".to_sym
      define_method(name) do
        if instance_variable_defined? var
          instance_variable_get(var)
        else
          clazz = Entity.find_class(options[:class])
          instance_variable_set(var, HasMany.new(clazz, "#{key}:#{name}"))
        end
      end
    end
    
    def self.has_one(name, options)
      var = "@association_#{name}".to_sym
      define_method(name) do
        if instance_variable_defined? var
          instance_variable_get(var)
        else
          clazz = Entity.find_class(options[:class])
          value_key = redis.get("#{key}:#{name}")
          instance_variable_set(var, clazz.find(value_key)) if value_key
        end
      end
      define_method("#{name}=") do |value|
        if value
          instance_variable_set(var, value)
          redis.set("#{key}:#{name}", value.key)
        else
          remove_instance_variable(var)
          redis.del("#{key}:#{name}")
        end
      end
    end
    
  private
  
    def self.fetch(key)
      redis.get(key) || raise(EntityNotFound, "no #{name} with key #{key}")
    end
  
    def self.next_key
      counter = redis.incr("#{key_prefix}:seq")
      "#{key_prefix}:#{counter}"
    end
  
    def self.key_prefix
      @key_prefix ||= name[0,1].downcase
    end
    
    # converts String, Symbol or Class into Class
    def self.find_class(clazz)
      Kernel.const_get(clazz.to_s) if clazz
    end
    
    def self.parse(json)
      unpack(Yajl::Parser.parse(json))
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
    
    def self.mapper
      @mapper ||= {}
    end
    
    def self.redis
      Remodel.redis
    end
    
    def redis
      Remodel.redis
    end
  end
  
  def self.redis
    @redis ||= Redis.new
  end
  
  def self.mapper_by_class
    @mapper_by_class ||= Hash.new(Mapper.new).merge(
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

