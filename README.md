remodel your storage layer -- use redis instead of mysql.

redis offers in-memory read and write performance --
on the order of 10K to 100K operations per second, comparable
to memcached -- plus asynchronous persistence to disk.

remodel is meant as a direct replacement for ActiveRecord and
offers familiar syntax (like has_many / belongs_to) to build
your domain model in ruby.

current status: pre-alpha. play around with this at your own risk :)
