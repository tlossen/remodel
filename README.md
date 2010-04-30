# remodel your storage layer

use [redis](http://github.com/antirez/redis) instead of mysql to store your application data.

remodel (= redis model) is an ActiveRecord-like mapping layer which offers familiar syntax 
like `has_many`, `has_one` etc. to build your domain model in ruby.


## why redis?

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

2. start redis:

		$ ./redis-server

3. now the tests should run successfully:

		$ rake
		Started
		.......................................................................................
		Finished in 0.072304 seconds.
		87 tests, 138 assertions, 0 failures, 0 errors

## example

define your domain model [like this](http://github.com/tlossen/remodel/blob/master/example/book.rb):

	class Book < Remodel::Entity
	  has_many :chapters, :class => 'Chapter', :reverse => :book
	  property :title, :class => 'String'
	  property :year, :class => 'Integer'
	end

	class Chapter < Remodel::Entity
	  has_one :book, :class => Book, :reverse => :chapters
	  property :title, :class => String
	end
	
now you can do:

	>> require 'example/book'
	=> true
	>> book = Book.create :title => 'Moby Dick', :year => 1851
	=> #<Book(b:3) title: "Moby Dick", year: 1851>
	>> chapter = book.chapters.create :title => 'Ishmael'
	=> #<Chapter(c:4) title: "Ishmael">
	>> chapter.book
	=> #<Book(b:3) title: "Moby Dick", year: 1851>


## inspired by

* [how to redis](http://www.paperplanes.de/2009/10/30/how_to_redis.html)
&mdash; good overview of different mapping options by [mattmatt](http://github.com/mattmatt).
* [hurl](http://github.com/defunkt/hurl) &mdash; basically
defunkts [Hurl::Model](http://github.com/defunkt/hurl/blob/master/models/model.rb) is what i started with.
* [ohm](http://github.com/soveran/ohm) &mdash; object-hash mapping for redis. 
somewhat similar, but instead of serializing to json, stores each attribute under a separate key.


## todo

* better docs
* `find_by`
* make serializer (json, messagepack, marshal ...) configurable
* benchmarks


## status

still pretty alpha &mdash; play around at your own risk :)


## license

[MIT](http://github.com/tlossen/remodel/raw/master/LICENSE), baby!