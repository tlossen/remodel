module Remodel

  # Represents the many-end of a many-to-one or many-to-many association.
  class HasMany < Array
    def initialize(this, clazz, key, reverse = nil)
      super _fetch(clazz, this.context, key)
      @this, @clazz, @key, @reverse = this, clazz, key, reverse
    end

    def create(attributes = {})
      add(@clazz.create(@this.context, attributes))
    end

    def find(id)
      detect { |x| x.id == id } || raise(EntityNotFound, "no element with id #{id}")
    end

    def add(entity)
      _add_to_reverse_association_of(entity) if @reverse
      _add(entity)
    end

    def remove(entity)
      _remove_from_reverse_association_of(entity) if @reverse
      _remove(entity)
    end

  private

    def _add(entity)
      self << entity
      _store
      entity
    end

    def _remove(entity)
      delete_if { |x| x.key == entity.key }
      _store
      entity
    end

    def _add_to_reverse_association_of(entity)
      if entity.send(@reverse).is_a? HasMany
        entity.send(@reverse).send(:_add, @this)
      else
        entity.send("_#{@reverse}=", @this)
      end
    end

    def _remove_from_reverse_association_of(entity)
      if entity.send(@reverse).is_a? HasMany
        entity.send(@reverse).send(:_remove, @this)
      else
        entity.send("_#{@reverse}=", nil)
      end
    end

    def _store
      @this.context.hset(@key, JSON.generate(self.map(&:key)))
    end

    def _fetch(clazz, context, key)
      keys = JSON.parse(context.hget(key) || '[]').uniq
      values = keys.empty? ? [] : context.hmget(*keys)
      keys.zip(values).map do |key, json|
        clazz.restore(context, key, json) if json
      end.compact
    end
  end

end
