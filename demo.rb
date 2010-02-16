require 'lib/remodel'

b = Remodel::Base.new(:bool => true, :list => [1,2,3])
puts b.to_json

b2 = Remodel::Base.from_json(b.to_json)
puts b2.inspect