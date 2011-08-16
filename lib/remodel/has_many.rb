module Remodel

  # Represents the many-end of a many-to-one or many-to-many association.
  class HasMany < Array
    def initialize(this, clazz, key)
      super _fetch(clazz, this.context, key)
      @this, @clazz, @key = this, clazz, key
    end

    def create(attributes = {})
      add(@clazz.create(@this.context, attributes))
    end

    def find(id)
      detect { |x| x.id == id } || raise(EntityNotFound, "no element with id #{id}")
    end

    def add(entity)
      self << entity
      _store
      entity
    end

    def remove(entity)
      delete_if { |x| x.key == entity.key }
      _store
      entity
    end

  private

    def _store
      @this.context.hset(@key, self.map(&:key).join(' '))
    end

    def _fetch(clazz, context, key)
      keys = (context.hget(key) || '').split.uniq
      values = keys.empty? ? [] : context.hmget(*keys)
      keys.zip(values).map do |key, json|
        clazz.restore(context, key, json) if json
      end.compact
    end
  end

end
