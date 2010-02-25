# remodel your storage layer

use [redis](http://code.google.com/p/redis/) instead of mysql 
to store your application data. 
redis offers in-memory read and write performance &mdash;
on the order of 10K to 100K operations per second (= comparable
to [memcached](http://memcached.org/)) &mdash; plus asynchronous 
persistence to disk.

remodel is meant as a direct replacement for ActiveRecord and
offers familiar syntax (`has_many`, `belongs_to` ...) to build
your domain model in ruby.


## dependencies

	brew install yajl
	gem install yajl-ruby

	brew install redis
	gem install redis


## status

pre-alpha. play around with it at your own risk :)
