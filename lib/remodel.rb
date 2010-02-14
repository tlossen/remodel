require 'rubygems'
require 'yajl'
require 'redis'


data = { :bool => true, :list => [1,2,3] }

json = Yajl::Encoder.encode(data)

puts json

data2 = Yajl::Parser.parse(json)

puts data2.inspect