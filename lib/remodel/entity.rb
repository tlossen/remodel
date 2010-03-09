require 'yajl'
require 'set'

module Remodel

  class Entity
  
    def initialize(attributes = {})
      @attributes = {}
      attributes.each do |key, value| 
        send("#{key}=", value) if respond_to? "#{key}="
      end
    end
  
    def self.create(attributes = {})
      new(attributes).save
    end
  
    def self.from_json(json)
      new(parse(json))
    end
    
    def self.find(key)
      from_json(fetch(key))
    end

    def save
      self.key = self.class.next_key if key.nil?
      redis.set(key, to_json)
      self
    end
    
    def reload
      initialize(self.class.parse(self.class.fetch(key)))
      reset_collections
      self
    end

    def to_json
      Yajl::Encoder.encode(self.class.pack(@attributes))
    end

    def self.parse(json)
      unpack(Yajl::Parser.parse(json))
    end
    
  protected

    def self.set_key_prefix(prefix)
      raise InvalidKeyPrefix unless prefix =~ /^[a-z]+$/
      @key_prefix = prefix
    end

    def self.property(name, options = {})
      name = name.to_sym
      mapper[name] = options[:mapper] || DefaultMapper
      define_method(name) { @attributes[name] }
      define_method("#{name}=") { |value| @attributes[name] = value }
    end
    
    def self.has_many(name, options)
      name = name.to_sym
      define_method(name) do
        var = "@collection_#{name}".to_sym
        if instance_variable_defined? var
          instance_variable_get var
        else
          instance_variable_set var, Collection.new(options[:class], "#{key}:#{name}")
        end
      end
    end
          
  private
  
    def self.inherited(subclass)
      subclass.property(:key)
    end

    def reset_collections
      instance_variables.each do |var|
        remove_instance_variable(var) if var =~ /^@collection_/
      end
    end
  
    def self.fetch(key)
      redis.get(key) || raise(EntityNotFound)
    end
  
    def self.next_key
      next_val = redis.incr("#{key_prefix}:seq")
      "#{key_prefix}:#{next_val}"
    end
  
    def self.key_prefix
      @key_prefix ||= name[0,1].downcase
    end
    
    def self.pack(attributes)
      result = {}
      attributes.each do |key, value|
        result[key] = mapper[key].pack(value)
      end
      result
    end
    
    def self.unpack(attributes)
      result = {}
      attributes.each do |key, value|
        key = key.to_sym
        result[key] = mapper[key].unpack(value)
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

end