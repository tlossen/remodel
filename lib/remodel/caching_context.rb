# encoding: UTF-8
module Remodel

  class CachingContext

    # use Remodel.create_context instead
    class << self
      private :new
    end

    def initialize(context)
      @context = context
      @cache = {}
    end

    def key
      @context.key
    end

    def hget(field)
      @cache[field] = @context.hget(field) unless @cache.has_key?(field)
      @cache[field]
    end

    def hmget(*fields)
      load(fields - @cache.keys)
      @cache.values_at(*fields)
    end

    def hset(field, value)
      value = value.to_s if value
      @cache[field] = value
      @context.hset(field, value)
    end

    def hincrby(field, value)
      result = @context.hincrby(field, value)
      @cache[field] = result.to_s
      result
    end

    def hdel(field)
      @cache[field] = nil
      @context.hdel(field)
    end

    def inspect
      "\#<#{self.class.name}(#{@context.inspect})>"
    end

  private

    def load(fields)
      return if fields.empty?
      fields.zip(@context.hmget(*fields)).each do |field, value|
        @cache[field] = value
      end
    end

  end

end