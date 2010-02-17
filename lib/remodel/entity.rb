class Remodel::Entity
  
  def initialize(attributes = {})
    @attributes = normalize(attributes)
  end
  
  def self.from_json(json)
    new(Yajl::Parser.parse(json))
  end

  def to_json
    Yajl::Encoder.encode(@attributes)
  end

protected

  def self.property(name)
    name = name.to_sym
    properties << name  
    define_method(name) { @attributes[name] }
    define_method("#{name}=") { |value| @attributes[name] = value }
  end

  def self.properties
    @properties ||= Set.new
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
