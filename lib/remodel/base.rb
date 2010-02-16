module Remodel
  
  class Base
    
    def self.from_json(json)
      new(Yajl::Parser.parse(json))
    end

    def initialize(attributes)
      @attributes = attributes.clone
    end
    
    def to_json
      Yajl::Encoder.encode(@attributes)
    end
    
  end
  
end