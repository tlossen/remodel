module Remodel

  class Entity
  
    def initialize(attributes = {})
      @attributes = self.class.normalize(attributes)
    end
  
    def self.create(attributes = {})
      new(attributes).save
    end
  
    def self.find(key)
      from_json(redis.get(key) || raise(EntityNotFound))
    end

    def reload
      initialize(self.class.parse(redis.get(key)))
      reset_collections
      self
    end

    def save
      self.key = self.class.next_key if key.nil?
      redis.set(key, to_json)
      self
    end
    
    def to_json
      Yajl::Encoder.encode(@attributes)
    end

  protected

    def self.next_key
      next_val = redis.incr("#{key_prefix}:seq")
      "#{key_prefix}:#{next_val}"
    end
    
    def self.key_prefix
      @key_prefix ||= name[0,1].downcase
    end

    def self.set_key_prefix(prefix)
      raise InvalidKeyPrefix unless prefix =~ /^[a-z]+$/
      @key_prefix = prefix
    end

    def self.inherited(subclass)
      subclass.property(:key)
    end

    def self.property(name)
      name = name.to_sym
      properties << name
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
          
    def self.redis
      Remodel.redis
    end
  
    def redis
      Remodel.redis
    end
  
  private
  
    def reset_collections
      instance_variables.each do |var|
        remove_instance_variable(var) if var =~ /^@collection_/
      end
    end
  
    def self.properties
      @properties ||= Set.new
    end
    
    def self.from_json(json)
      new(parse(json))
    end
    
    def self.parse(json)
      Yajl::Parser.parse(json)
    end

    def self.normalize(attributes)
      result = {}
      attributes.each do |name, value|
        name = name.to_sym
        result[name] = value if properties.include? name
      end
      result
    end
  
  end

end