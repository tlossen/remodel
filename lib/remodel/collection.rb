module Remodel

  class Collection < Array
    
    def initialize(clazz, key)
      clazz = Kernel.const_get(clazz.to_s) # accepts String, Symbol or Class
      super fetch(clazz, key)
      @clazz = clazz
      @key = key
    end
    
    def create(attributes = {})
      self << created = @clazz.create(attributes)
      redis.rpush(@key, created.key)
      created
    end

  private
  
    def fetch(clazz, key)
      keys = redis.lrange(key, 0, -1)
      keys.empty? ? [] : redis.mget(keys).map { |json| clazz.from_json(json) }
    end
    
    def redis
      Remodel.redis
    end

  end

end