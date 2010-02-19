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
      redis.incr("#{self.name}:key-sequence")
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
    
    def self.has_many(children)
      define_method(children.to_sym) { [] }
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