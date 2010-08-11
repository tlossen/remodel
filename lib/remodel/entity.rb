module Remodel

  # The superclass of all persistent remodel entities.
  class Entity
    attr_accessor :context, :key

    def initialize(context, attributes = {}, key = nil)
      @context = context
      @attributes = {}
      @key = key
      attributes = self.class.default_values.merge(attributes) if key.nil?
      attributes.each do |name, value|
        send("#{name}=", value) if respond_to? "#{name}="
      end
    end

    def id
      key && key.match(/\d+/)[0].to_i
    end

    def save
      @key = next_key unless @key
      Remodel.redis.hset(@context, @key, to_json)
      self
    end

    def update(properties)
      properties.each { |name, value| send("#{name}=", value) }
      save
    end

    def reload
      raise EntityNotSaved unless @key
      initialize(@context, self.class.parse(self.class.fetch(@context, @key)), @key)
      instance_variables.each do |var|
        remove_instance_variable(var) if var =~ /^@association_/
      end
      self
    end

    def delete
      raise EntityNotSaved unless @key
      Remodel.redis.hdel(@context, @key)
      instance_variables.each do |var|
        Remodel.redis.hdel(@context, var.sub('@association', @key)) if var =~ /^@association_/
      end
    end

    def as_json
      { :id => id }.merge(@attributes)
    end

    def to_json
      JSON.generate(self.class.pack(@attributes))
    end

    def inspect
      properties = @attributes.map { |name, value| "#{name}: #{value.inspect}" }.join(', ')
      "\#<#{self.class.name}(#{context}, #{id}) #{properties}>"
    end

    def self.create(context, attributes = {})
      new(context, attributes).save
    end

    def self.find(context, key)
      key = "#{key_prefix}#{key}" if key.kind_of? Integer
      restore(context, key, fetch(context, key))
    end

    def self.restore(context, key, json)
      new(context, parse(json), key)
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
          instance_variable_set(var, HasMany.new(self, clazz, "#{key}_#{name}", options[:reverse]))
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
          value_key = Remodel.redis.hget(self.context, "#{key}_#{name}")
          instance_variable_set(var, clazz.find(self.context, value_key)) if value_key
        end
      end

      define_method("#{name}=") do |value|
        send("_reverse_association_of_#{name}=", value) if options[:reverse]
        send("_#{name}=", value)
      end

      define_method("_#{name}=") do |value|
        if value
          instance_variable_set(var, value)
          Remodel.redis.hset(self.context, "#{key}_#{name}", value.key)
        else
          remove_instance_variable(var) if instance_variable_defined? var
          Remodel.redis.hdel(self.context, "#{key}_#{name}")
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

    def self.fetch(context, key)
      Remodel.redis.hget(context, key) || raise(EntityNotFound, "no #{name} with key #{key} in context #{context}")
    end

    # Each entity has its own sequence to generate unique ids.
    def next_key
      id = Remodel.redis.hincrby(@context, "#{self.class.key_prefix}", 1)
      "#{self.class.key_prefix}#{id}"
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