module Remodel

  class DefaultMapper
    def self.pack(value)
      value
    end
    
    def self.unpack(value)
      value
    end
  end
  
  class SimpleMapper
    def initialize(clazz, pack_method, unpack_method)
      @clazz = clazz
      @pack_method = pack_method
      @unpack_method = unpack_method
    end
    
    def pack(value)
      return nil if value.nil?
      raise InvalidType unless value.is_a? @clazz
      value.send(@pack_method)
    end
    
    def unpack(value)
      return nil if value.nil?
      @clazz.send(@unpack_method, value)
    end
  end

end
