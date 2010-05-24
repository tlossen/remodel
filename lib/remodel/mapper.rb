module Remodel

  # A mapper converts a given value into a native JSON value &mdash;
  # *nil*, *true*, *false*, *Number*, *String*, *Hash*, *Array* &mdash;
  # via `pack`, and back again via `unpack`.
  #
  # Without any arguments, `Mapper.new` returns the identity mapper, which
  # maps every value to itself. If `clazz` is set, the mapper rejects any
  # value which is not of the given type.
  class Mapper
    def initialize(clazz = nil, pack_method = nil, unpack_method = nil)
      @clazz = clazz
      @pack_method = pack_method
      @unpack_method = unpack_method
    end

    def pack(value)
      return nil if value.nil?
      raise(InvalidType, "#{value.inspect} is not a #{@clazz}") if @clazz && !value.is_a?(@clazz)
      @pack_method ? value.send(@pack_method) : value
    end

    def unpack(value)
      return nil if value.nil?
      @unpack_method ? @clazz.send(@unpack_method, value) : value
    end
  end

end
