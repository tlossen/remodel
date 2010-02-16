module Remodel
  
  class Base
    
    def self.property(name)
      name = name.to_sym
      
      @properties ||= []
      @properties << name
      
      define_method(name) do
        @attributes[name]
      end
      
      define_method("#{name}=") do |value|
        @attributes[name] = value
      end
    end
    
    def self.from_json(json)
      new(Yajl::Parser.parse(json))
    end

    def initialize(attributes = {})
      @attributes = attributes.clone
    end
    
    def to_json
      Yajl::Encoder.encode(@attributes)
    end
    
  end
  
end