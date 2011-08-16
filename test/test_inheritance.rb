require 'helper'

class TestInheritance < Test::Unit::TestCase

  class Foo < Remodel::Entity
    property :test
  end

  class Bar < Remodel::Entity
    property :test
  end

  class Person < Remodel::Entity
    property :name, :short => 'n'
    has_one  :foo, :class => Foo
    has_many :foos, :class => Foo
  end

  class Admin < Person
    property :password, :short => 'p'
    has_one  :bar, :class => Bar
    has_many :bars, :class => Bar
  end

  context "a subclass of another entity" do
    setup do
      @admin = Admin.create(context, :name => 'peter', :password => 'secret')
    end

    should "inherit properties" do
      @admin.reload
      assert_equal 'peter', @admin.name
      assert_equal 'secret', @admin.password
    end

    should "inherit has_one associations" do
      @admin.foo = Foo.create(context, :test => 'foo')
      @admin.bar = Bar.create(context, :test => 'bar')
      @admin.reload
      assert_equal 'foo', @admin.foo.test
      assert_equal 'bar', @admin.bar.test
    end

    should "inherit has_many associations" do
      @admin.foos.create(:test => 'foo')
      @admin.bars.create(:test => 'bar')
      @admin.reload
      assert_equal 'foo', @admin.foos[0].test
      assert_equal 'bar', @admin.bars[0].test
    end

    should "be usable as superclass" do
      person = Person.find(context, @admin.key)
      assert_equal 'peter', person.name
      assert_raise(NoMethodError) { person.password }
    end

    should "use property shortnames in redis" do
      json = redis.hget(context.key, @admin.key)
      assert_match /"n":/, json
      assert_match /"p":/, json
    end
  end

end