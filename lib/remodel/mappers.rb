module Remodel

  class IdentityMapper
    def initialize(clazz = nil)
      @clazz = clazz
    end
    
    def pack(value)
      return nil if value.nil?
      raise InvalidType if @clazz && !value.is_a?(@clazz)
      value
    end
  
    def unpack(value)
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
