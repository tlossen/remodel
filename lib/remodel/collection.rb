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
      keys.empty? ? [] : keys.zip(redis.mget(keys)).map { |key, json| clazz.restore(key, json) }
    end
    
    def redis
      Remodel.redis
    end

  end

end