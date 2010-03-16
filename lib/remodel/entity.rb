require 'yajl'

module Remodel

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
      clazz = Remodel.find_class(options[:class])
      mapper[name] = mapper_for(clazz)
      define_method(name) { @attributes[name] }
      define_method("#{name}=") { |value| @attributes[name] = value }
    end
    
    def self.has_many(name, options)
      name = name.to_sym
      define_method(name) do
        var = "@association_#{name}".to_sym
        if instance_variable_defined? var
          instance_variable_get var
        else
          instance_variable_set var, HasMany.new(options[:class], "#{key}:#{name}")
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
    
    def self.mapper_for(clazz)
      return IdentityMapper.new unless clazz
      clazz < Entity ? EntityMapper.new(clazz) : mapper_by_class[clazz]
    end
    
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
  
    def self.mapper
      @mapper ||= {}
    end
    
    def self.redis
      Remodel.redis
    end
  
  end

end