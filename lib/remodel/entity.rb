module Remodel

  # The superclass of all persistent remodel entities.
  class Entity
    attr_accessor :key

    def initialize(attributes = {}, key = nil)
      @attributes = {}
      @key = key
      attributes = self.class.default_values.merge(attributes) if key.nil?
      attributes.each do |name, value|
        send("#{name}=", value) if respond_to? "#{name}="
      end
    end

    def id
      key && key.split(':').last.to_i
    end

    def save
      @key = self.class.next_key unless @key
      Remodel.redis.hset(Remodel.context, @key, to_json)
      self
    end

    def update(properties)
      properties.each { |name, value| send("#{name}=", value) }
      save
    end

    def reload
      raise EntityNotSaved unless @key
      initialize(self.class.parse(self.class.fetch(@key)), @key)
      instance_variables.each do |var|
        remove_instance_variable(var) if var =~ /^@association_/
      end
      self
    end

    def delete
      raise EntityNotSaved unless @key
      Remodel.redis.hdel(Remodel.context, @key)
    end

    def as_json
      { :id => id }.merge(@attributes)
    end

    def to_json
      JSON.generate(self.class.pack(@attributes))
    end

    def inspect
      properties = @attributes.map { |name, value| "#{name}: #{value.inspect}" }.join(', ')
      "\#<#{self.class.name}(#{id}) #{properties}>"
    end

    def self.create(attributes = {})
      new(attributes).save
    end

    def self.find(key)
      key = "#{key_prefix}:#{key}" if key.kind_of? Integer
      restore(key, fetch(key))
    end

    def self.restore(key, json)
      new(parse(json), key)
    end

  protected # --- DSL for subclasses ---

    def self.set_key_prefix(prefix)
      raise(InvalidKeyPrefix, prefix) unless prefix =~ /^[a-z]+$/
      @key_prefix = prefix
    end

    def self.property(name, options = {})
      name = name.to_sym
      mapper[name] = Remodel.mapper_for(options[:class])
      default_values[name] = options[:default] if options.has_key?(:default)
      define_method(name) { @attributes[name] }
      define_method("#{name}=") { |value| @attributes[name] = value }
    end

    def self.has_many(name, options)
      var = "@association_#{name}".to_sym

      define_method(name) do
        if instance_variable_defined? var
          instance_variable_get(var)
        else
          clazz = Class[options[:class]]
          instance_variable_set(var, HasMany.new(self, clazz, "#{key}:#{name}", options[:reverse]))
        end
      end
    end

    def self.has_one(name, options)
      var = "@association_#{name}".to_sym

      define_method(name) do
        if instance_variable_defined? var
          instance_variable_get(var)
        else
          clazz = Class[options[:class]]
          value_key = Remodel.redis.hget(Remodel.context, "#{key}:#{name}")
          instance_variable_set(var, clazz.find(value_key)) if value_key
        end
      end

      define_method("#{name}=") do |value|
        send("_reverse_association_of_#{name}=", value) if options[:reverse]
        send("_#{name}=", value)
      end

      define_method("_#{name}=") do |value|
        if value
          instance_variable_set(var, value)
          Remodel.redis.hset(Remodel.context, "#{key}:#{name}", value.key)
        else
          remove_instance_variable(var) if instance_variable_defined? var
          Remodel.redis.hdel(Remodel.context, "#{key}:#{name}")
        end
      end; private "_#{name}="

      if options[:reverse]
        define_method("_reverse_association_of_#{name}=") do |value|
          if old_value = send(name)
            association = old_value.send("#{options[:reverse]}")
            if association.is_a? HasMany
              association.send("_remove", self)
            else
              old_value.send("_#{options[:reverse]}=", nil)
            end
          end
          if value
            association = value.send("#{options[:reverse]}")
            if association.is_a? HasMany
              association.send("_add", self)
            else
              value.send("_#{options[:reverse]}=", self)
            end
          end
        end; private "_reverse_association_of_#{name}="
      end
    end

  private # --- Helper methods ---

    def self.fetch(key)
      Remodel.redis.hget(Remodel.context, key) || raise(EntityNotFound, "no #{name} with key #{key}")
    end

    # Each entity has its own sequence to generate unique ids.
    def self.next_key
      id = Remodel.redis.hincrby(Remodel.context, "#{key_prefix}:seq", 1)
      "#{key_prefix}:#{id}"
    end

    # Default key prefix is the first letter of the class name, in lowercase.
    def self.key_prefix
      @key_prefix ||= name.split('::').last[0,1].downcase
    end

    def self.parse(json)
      unpack(JSON.parse(json))
    end

    def self.pack(attributes)
      result = {}
      attributes.each do |name, value|
        result[name] = mapper[name].pack(value)
      end
      result
    end

    def self.unpack(attributes)
      result = {}
      attributes.each do |name, value|
        name = name.to_sym
        result[name] = mapper[name].unpack(value)
      end
      result
    end

    # Lazy init
    def self.mapper
      @mapper ||= {}
    end

    def self.default_values
      @default_values ||= {}
    end

  end

end