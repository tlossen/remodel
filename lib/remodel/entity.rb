module Remodel

  class Entity
  
    def self.find(key)
      from_json(redis.get(key) || raise(EntityNotFound))
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
    
    def self.has_many(collection, options)
      clazz = options[:class]
      define_method(collection.to_sym) do
        var = "@#{collection}".to_sym
        if instance_variable_defined?(var)
          instance_variable_get(var)
        else
          collection_key = "#{key}:#{collection}"
          keys = redis.lrange(collection_key, 0, -1)
          values = keys.empty? ? [] : redis.mget(keys).map { |json| clazz.from_json(json) }
          eigenclass = class << values; self; end
          eigenclass.send(:define_method, :create) do |attributes|
            created = clazz.create(attributes)
            Remodel.redis.rpush(collection_key, created.key)
            self << created
          end
          instance_variable_set(var, values)
        end
      end
    end
    
    def self.belongs_to(parent)
      # TODO: implement this :)
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
        name = name.to_sym
        result[name] = value if self.class.properties.include? name
      end
      result
    end
  
  end

end