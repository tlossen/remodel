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

    def batched
      raise InvalidUse, "cannot nest batched blocks" if @dirty
      begin
        @dirty = Set.new
        yield
      ensure
        to_delete = @dirty.select { |field| @cache[field].nil? }
        to_update = (@dirty - to_delete).to_a
        @context.hmset(*to_update.zip(@cache.values_at(*to_update)).flatten)
        @context.hmdel(*to_delete)
        @dirty = nil
      end
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
      @dirty ? @dirty.add(field) : @context.hset(field, value)
    end

    def hincrby(field, value)
      new_value = @dirty ? hget(field).to_i + value : @context.hincrby(field, value)
      @cache[field] = new_value.to_s
      @dirty.add(field) if @dirty
      new_value
    end

    def hdel(field)
      @cache[field] = nil
      @dirty ? @dirty.add(field) : @context.hdel(field)
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