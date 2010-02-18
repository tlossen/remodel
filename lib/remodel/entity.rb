class Remodel::Entity
  
  def initialize(attributes = {})
    @attributes = normalize(attributes)
  end
  
  def self.create(attributes = {})
    new(attributes).save
  end
  
  def self.from_json(json)
    new(Yajl::Parser.parse(json))
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
    redis.incr "#{self.name}:key-sequence"
  end

  # class hook
  def self.inherited(subclass)
    subclass.property(:key)
  end

  def self.property(name)
    name = name.to_sym
    properties << name
    define_method(name) { @attributes[name] }
    define_method("#{name}=") { |value| @attributes[name] = value }    
  end

  def self.properties
    @properties ||= Set.new
  end
  
  def self.redis
    Remodel.redis
  end
  
  def redis
    Remodel.redis
  end
  
private

  def normalize(attributes)
    result = {}
    attributes.each do |name, value|
      result[name.to_sym] = value if self.class.properties.include? name.to_sym
    end
    result
  end
  
end