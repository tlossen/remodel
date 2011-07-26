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

    def hmset(*fields_and_values)
      return if fields_and_values.empty?
      Remodel.redis.hmset(@key, *fields_and_values)
    end

    def hincrby(field, value)
      Remodel.redis.hincrby(@key, field, value)
    end

    def hdel(field)
      Remodel.redis.hdel(@key, field)
    end

    def hmdel(*fields)
      return if fields.empty?
      Remodel.redis.pipelined do
        fields.each { |field| Remodel.redis.hdel(@key, field) }
      end
    end

    def inspect
      "\#<#{self.class.name}(#{@key})>"
    end
  end

end
