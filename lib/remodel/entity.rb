module Remodel

  class Entity
  
    def self.find(key)
      from_json(redis.get(key) || raise(NotFound))
    end

    def self.create(attributes = {})
      new(attributes).save
    end
  
    def initialize(attributes = {})
      @attributes = normalize(attributes)
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
      name[0,1].downcase
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
    
    def self.has_many(collection, options)
      define_method(collection.to_sym) do
        var = "@#{collection}".to_sym        
        if instance_variable_defined? var
          instance_variable_get var
        else
          keys = redis.lrange("#{key}:#{collection}", 0, -1)
          values = redis.mget(keys).map { |json| options[:class].from_json(json) }
          instance_variable_set var, values
        end
      end
    end
    
    def self.belongs_to(parent)
      define_method(parent.to_sym) { nil }
    end

    def self.redis
      Remodel.redis
    end
  
    def redis
      Remodel.redis
    end
  
  private
  
    def self.properties
      @properties ||= Set.new
    end

    def self.from_json(json)
      new(Yajl::Parser.parse(json))
    end

    def normalize(attributes)
      result = {}
      attributes.each do |name, value|
        result[name.to_sym] = value if self.class.properties.include? name.to_sym
      end
      result
    end
  
  end

end