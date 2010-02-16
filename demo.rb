require 'pet'

p = Pet.new(:foo => 42)
puts p.inspect
puts p.foo
p.foo = 23
puts p.foo
