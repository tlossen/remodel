module Remodel

  class HasMany < Array
    def initialize(clazz, key)
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
      values = keys.empty? ? [] : redis.mget(keys)
      keys.zip(values).map do |key, json|
        clazz.restore(key, json) if json
      end.compact
    end
    
    def redis
      Remodel.redis
    end
  end

end