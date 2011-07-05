module Remodel

  class Context

    # use Remodel.create_context instead
    class << self
      private :new
    end

    attr_reader :key

    def initialize(key)
      @key = key
    end

    def hget(field)
      Remodel.redis.hget(@key, field)
    end

    def hmget(*fields)
      Remodel.redis.hmget(@key, *fields)
    end

    def hset(field, value)
      Remodel.redis.hset(@key, field, value)
    end

    def hincrby(field, value)
      Remodel.redis.hincrby(@key, field, value)
    end

    def hdel(field)
      Remodel.redis.hdel(@key, field)
    end

    def inspect
      "\#<#{self.class.name}(#{@key})>"
    end
  end

end
