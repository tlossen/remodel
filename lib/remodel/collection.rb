module Remodel

  class Collection < Array
    
    def initialize(elements, clazz, key)
      super(elements)
      @clazz = clazz
      @key = key
    end
    
    def create(attributes = {})
      created = @clazz.create(attributes)
      Remodel.redis.rpush(@key, created.key)
      self << created
      created
    end
    
  end

end