# remodel your storage layer!


## overview

use [redis](http://github.com/antirez/redis) instead of mysql to store your application data.
remodel (= redis model) is meant as a direct replacement for ActiveRecord and
offers familiar syntax like `has_many`, `belongs_to` etc. to build your domain model in ruby.

redis offers in-memory read and write performance &mdash; on the order of 10K to 100K 
operations per second, comparable to [memcached](http://memcached.org/) &mdash; plus asynchronous
persistence to disk. for example, on my macbook (2 Ghz):

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

3. start redis, i.e.

		$ redis-server

4. now the tests should run successfully

		$ rake
		Finished in 0.011021 seconds.
		21 tests, 36 assertions, 0 failures, 0 errors


## example

define your domain model like this:

	class Chapter < Remodel::Entity
	  property :title
	end
	
	class Book < Remodel::Entity
	  has_many :chapters, :class => Chapter
	  property :title
	  property :year
	end
	
now you can do:

	>> book = Book.create :title => 'Moby Dick', :year => 1851
	=> #<Book:0x11cc20c @attributes={:key=>"b:1", :year=>1851, :title=>"Moby Dick"}>
	>> book.key
	=> "b:1"
	>> book.chapters.create :title => 'Ishmael'
	=> [#<Chapter:0x11d0578 @attributes={:key=>"c:1", :title=>"Ishmael"}>]
	>> book.chapters.size
	=> 1


## inspired by

* [how to redis](http://www.paperplanes.de/2009/10/30/how_to_redis.html)
&mdash; good overview of differenct mapping options by [mattmatt](http://github.com/mattmatt)
* [hurl](http://github.com/defunkt/hurl) &mdash; basically i extracted
defunkts [Hurl::Model](http://github.com/defunkt/hurl/blob/master/models/model.rb) class 
into [Remodel::Entity](http://github.com/tlossen/remodel/blob/master/lib/remodel/entity.rb)
* [ohm](http://github.com/soveran/ohm) &mdash; object-hash mapping for redis. 
somewhat similar, althoug based on a different mapping approach: not serialization to json,
but storing each attribute under its own key.


## todo

* `belongs_to`
* `delete`
* redis config
* documentation (yardoc)
* packaging as gem
* benchmarks
* `find_by` with ohm-like indexes?
* sharding??


## status

alpha. play around at your own risk :)


## license

[MIT](http://github.com/tlossen/remodel/raw/master/LICENSE), baby!