module Remodel

  # The superclass of all persistent remodel entities.
  class Entity
    attr_accessor :context, :key

    def initialize(context, attributes = {}, key = nil)
      @context = context
      @attributes = {}
      @key = key
      attributes.each do |name, value|
        send("#{name}=", value) if respond_to? "#{name}="
      end
    end

    def id
      key && key.match(/\d+/)[0].to_i
    end

    def save
      @key = next_key unless @key
      @context.hset(@key, to_json)
      self
    end

    def update(properties)
      properties.each { |name, value| send("#{name}=", value) }
      save
    end

    def reload
      raise EntityNotSaved unless @key
      attributes = self.class.parse(self.class.fetch(@context, @key))
      initialize(@context, attributes, @key)
      self.class.associations.each do |name|
        var = "@#{name}".to_sym
        remove_instance_variable(var) if instance_variable_defined? var
      end
      self
    end

    def delete
      raise EntityNotSaved unless @key
      @context.hdel(@key)
      self.class.associations.each do |name|
        @context.hdel("#{@key}_#{name}")
      end
    end

    def as_json
      { :id => id }.merge(attributes)
    end

    def to_json
      JSON.generate(self.class.pack(@attributes))
    end

    def inspect
      properties = attributes.map { |name, value| "#{name}: #{value.inspect}" }.join(', ')
      "\#<#{self.class.name}(#{context.key}, #{id}) #{properties}>"
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
      _mapper[name] = Remodel.mapper_for(options[:class])
      define_shortname(name, options[:short])
      default_value = options[:default]
      define_method(name) { @attributes[name].nil? ? self.class.copy_of(default_value) : @attributes[name] }
      define_method("#{name}=") { |value| @attributes[name] = value }
    end

    def self.has_many(name, options)
      _associations.push(name)
      var = "@#{name}".to_sym

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
      _associations.push(name)
      var = "@#{name}".to_sym

      define_method(name) do
        if instance_variable_defined? var
          instance_variable_get(var)
        else
          clazz = Class[options[:class]]
          value_key = self.context.hget("#{key}_#{name}")
          value = value_key && clazz.find(self.context, value_key) rescue nil
          instance_variable_set(var, value)
        end
      end

      define_method("#{name}=") do |value|
        send("_reverse_association_of_#{name}=", value) if options[:reverse]
        send("_#{name}=", value)
      end

      define_method("_#{name}=") do |value|
        if value
          instance_variable_set(var, value)
          self.context.hset("#{key}_#{name}", value.key)
        else
          remove_instance_variable(var) if instance_variable_defined? var
          self.context.hdel("#{key}_#{name}")
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

    def attributes
      result = {}
      self.class.mapper.keys.each do |name|
        result[name] = send(name)
      end
      result
    end

    def self.fetch(context, key)
      context.hget(key) || raise(EntityNotFound, "no #{name} with key #{key} in context #{context}")
    end

    # Each entity has its own sequence to generate unique ids.
    def next_key
      id = @context.hincrby("#{self.class.key_prefix}", 1)
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
        short = shortname[name] || name
        value = mapper[name].pack(value)
        result[short] = value unless value.nil?
      end
      result
    end

    def self.unpack(attributes)
      result = {}
      attributes.each do |short, value|
        short = short.to_sym
        name = fullname[short] || short
        result[name] = mapper[name].unpack(value) if mapper[name]
      end
      result
    end

    def self.copy_of(value)
      value.is_a?(Array) || value.is_a?(Hash) ? value.dup : value
    end

    def self.define_shortname(name, short)
      return unless short
      short = short.to_sym
      _shortname[name] = short
      _fullname[short] = name
    end

    # class instance variables:
    # lazy init + recursive lookup in superclasses

    def self.mapper
      self == Entity || superclass == Entity ? _mapper : superclass.mapper.merge(_mapper)
    end

    def self._mapper
      @mapper ||= {}
    end

    def self.shortname
      self == Entity || superclass == Entity ? _shortname : superclass.shortname.merge(_shortname)
    end

    def self._shortname
      @shortname ||= {}
    end

    def self.fullname
      self == Entity || superclass == Entity ? _fullname : superclass.fullname.merge(_fullname)
    end

    def self._fullname
      @fullname ||= {}
    end

    def self.associations
      self == Entity || superclass == Entity ? _associations : superclass.associations + _associations
    end

    def self._associations
      @associations ||= []
    end

  end

end