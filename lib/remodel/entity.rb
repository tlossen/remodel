module Remodel
  
  class Entity
    
    def self.property(name)
      name = name.to_sym
      
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
      @attributes = symbolize_keys attributes
    end
    
    def to_json
      Yajl::Encoder.encode(@attributes)
    end
    
  private
    
    def symbolize_keys(hash)
      result = {}
      hash.each do |key, value|
        result[key.to_sym] = value
      end
      result
    end
    
  end
  
end