# remodel your storage layer!

use [redis](http://github.com/antirez/redis) instead of mysql to store your application data.


## overview

remodel (= redis model) is meant as a direct replacement for active record and
offers familiar syntax like `has_many`, `belongs_to` etc. to build your domain model in ruby.

redis offers in-memory read and write performance &mdash; on the order of 10K to 100K 
operations per second, comparable to [memcached](http://memcached.org/) &mdash; plus asynchronous
persistence to disk. for example, on my macbook (2 ghz):

	$ redis-benchmark -d 100 -r 10000 -q
	SET: 13864.27 requests per second
	GET: 18152.17 requests per second
	INCR: 17006.80 requests per second
	LPUSH: 17243.99 requests per second
	LPOP: 18706.54 requests per second



## how to get started

1. install [redis](http://github.com/antirez/redis) and ezras excellent
[redis-rb](http://github.com/ezmobius/redis-rb) ruby client:

		$ brew install redis
		$ gem install redis

2. install the super-fast [yajl](http://github.com/lloyd/yajl) json parser
plus ruby bindings:

		$ brew install yajl
		$ gem install yajl-ruby

3. start redis:

		$ redis-server

4. now the tests should run successfully:

		$ rake
		Started
		.........................................
		Finished in 0.025785 seconds.
		41 tests, 74 assertions, 0 failures, 0 errors


## example

define your domain model [like this](http://github.com/tlossen/remodel/blob/master/example/book.rb):

	class Book < Remodel::Entity
	  has_many :chapters, :class => 'Chapter'
	  property :title, :class => String
	  property :year, :class => Integer
	end

	class Chapter < Remodel::Entity
	  property :title, :class => String
	end
	
now you can do:

	>> require 'example/book'
	=> true
	>> book = Book.create :title => 'Moby Dick', :year => 1851
	=> #<Book:0x11e08d8 @key="b:1", @attributes={:year=>1851, :title=>"Moby Dick"}>
	>> book.chapters.create :title => 'Ishmael'
	=> #<Chapter:0x11dd73c @key="c:1", @attributes={:title=>"Ishmael"}>
	>> book.chapters.size
	=> 1


## inspired by

* [how to redis](http://www.paperplanes.de/2009/10/30/how_to_redis.html)
&mdash; good overview of differenct mapping options by [mattmatt](http://github.com/mattmatt)
* [hurl](http://github.com/defunkt/hurl) &mdash; basically i extracted
defunkts [Hurl::Model](http://github.com/defunkt/hurl/blob/master/models/model.rb) class 
into [Remodel::Entity](http://github.com/tlossen/remodel/blob/master/lib/remodel/entity.rb)
* [ohm](http://github.com/soveran/ohm) &mdash; object-hash mapping for redis. 
somewhat similar, but instead of serializing to json, stores each attribute under a separate key.


## todo

* `belongs_to`
* `delete`
* redis config
* benchmarks
* documentation ([rocco](http://github.com/rtomayko/rocco))
* package as gem
* `find_by` with ohm-like indexes
* maybe switch to redis hashes later?


## status

alpha. play around at your own risk :)


## license

[MIT](http://github.com/tlossen/remodel/raw/master/LICENSE), baby!