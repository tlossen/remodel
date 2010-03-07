module Remodel

  class DefaultMapper
    def self.pack(value)
      value
    end
    
    def self.unpack(value)
      value
    end
  end

  class TimeMapper
    def self.pack(value)
      value.to_i
    end
    
    def self.unpack(value)
      Time.at(value)
    end
  end

  def self.redis
    @redis ||= Redis.new
  end
  
end
