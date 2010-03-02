module Remodel
  
  class Error < ::StandardError; end
  class EntityNotFound < Error; end  
  class InvalidKeyPrefix < Error; end

end