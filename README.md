# remodel your storage layer!


## overview

use [redis](http://code.google.com/p/redis/) instead of mysql
to store your application data. 
redis offers in-memory read and write performance &mdash;
on the order of 10K to 100K operations per second, comparable
to [memcached](http://memcached.org/) &mdash; plus asynchronous 
persistence to disk.

remodel (= redis model) is meant as a direct replacement for ActiveRecord and
offers familiar syntax like `has_many`, `belongs_to` ... to build
your domain model in ruby.


## how to get started

1. install redis and ezras [redis-rb](http://github.com/ezmobius/redis-rb) ruby client:

		brew install redis
		gem install redis

2. install the super-fast [yajl](http://github.com/lloyd/yajl) json parser plus ruby bindings:

		brew install yajl
		gem install yajl-ruby

3. start redis, i.e.

		redis-server

4. now the tests should run successfully

		rake
	
		Finished in 0.011021 seconds.
		
		21 tests, 36 assertions, 0 failures, 0 errors


## usage example

define your domain model like this:

	class Chapter < Remodel::Entity
	  property :title
	end
	
	class Book < Remodel::Entity
	  has_many :chapters, :class => Chapter
	  property :title
	  property :year
	end
	
then you can do:

	>> book = Book.create :title => 'Moby Dick', :year => 1851
	=> #<Book:0x11cc20c @attributes={:key=>"b:1", :year=>1851, :title=>"Moby Dick"}>
	>> book.key
	=> "b:1"
	>> book.chapters.create :title => 'Ishmael'
	=> [#<Chapter:0x11d0578 @attributes={:key=>"c:1", :title=>"Ishmael"}>]
	>> book.chapters.size
	=> 1


## inspired by

* [how to redis](http://www.paperplanes.de/2009/10/30/how_to_redis.html) &mdash; good overview by mathias meyer
* [hurl](http://github.com/defunkt/hurl) &mdash; basically i extracted defunkts [Hurl::Model](http://github.com/defunkt/hurl/blob/master/models/model.rb) class into [Remodel::Entity](http://github.com/tlossen/remodel/blob/master/lib/remodel/entity.rb)
* [ohm](http://github.com/soveran/ohm) &mdash; object-hash mapping for redis. somewhat similar, but uses a different mapping approach.


## todo

* `belongs_to`
* `delete`
* custom key prefixes
* redis config
* ohm-like indexes?
* documentation (yardoc)
* sharding


## status

pre-alpha. play around with it at your own risk :)


## license

[MIT](http://github.com/tlossen/remodel/raw/master/LICENSE), baby!